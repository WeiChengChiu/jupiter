class TodoPublishContext < BaseContext
  include RecordHelper

  attr_reader :today_doing_todos, :doing_todos

  before_perform :to_messages
  before_perform :append_total_hours
  before_perform :slack_setting
  after_perform :update_user_todos_published

  class << self
    def perform(user_id, opts = {})
      user = User.find(user_id)
      new(user).perform(opts)
    end
  end

  def initialize(user)
    @user = user

    @finished_todos = @user.todos.project_sorted.today_finished
    @today_doing_todos = @user.todos.today_doing_and_not_finished.sorted
    @doing_todos = @user.todos.sorted.doing
  end

  def perform(skip_user_update: false)
    @skip_user_update = skip_user_update
    run_callbacks :perform do
      @messages << '---------------------------------------'
      SlackService.notify_async(@messages.join("\n"), @slack_setting)
    end
  end

  private

  def to_messages
    @messages = ["#{@user.name} 本日工作報告:", '']
    { '[今日已完成]' => @finished_todos, '[今日有做 & 未完成]' => @today_doing_todos, '[明日預定]' => @doing_todos }.each do |title, todos|
      @messages << title
      todos.includes(:project, :records).each do |todo|
        msg = "#{todo.project.name} - #{todo.desc}"
        if todo.total_time > 0
          today_hours = render_hours(todo.records.today.total_time)
          today_hours = "#{today_hours} / " if today_hours.present?
          msg = "#{msg} (#{today_hours}#{render_hours(todo.total_time)})"
        end
        @messages << msg
      end
      @messages << '無' if todos.count == 0
      @messages << ''
    end
  end

  def append_total_hours
    @messages << "今日累積工時: #{render_hours @user.records.today.total_time}"
    @messages << "本月累積工時: #{render_hours @user.records.this_month.total_time}"
  end

  # TODO: team
  def slack_setting
    @slack_setting = { channel: '#standup-meeting' }
  end

  def update_user_todos_published
    return true if @skip_user_update
    @user.update(todos_published: true)
  end
end
