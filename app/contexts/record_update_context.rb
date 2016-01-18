class RecordUpdateContext < BaseContext
  PERMITS = [:minutes, :note, :record_type]

  before_perform :validates_user!
  before_perform :assign_value

  def initialize(user, record)
    @user = user
    @record = record
  end

  def perform(params)
    @params = permit_params( params[:record] || params, PERMITS )
    run_callbacks :perform do
      if @record.save
        @record
      else
        add_error(:update_record_fail, @record.errors.full_messages.join("\n"))
      end
    end
  end

  private

  def validates_user!
    return add_error(:user_is_not_owner) unless @record.user_id ==  @user.id
    true
  end

  def assign_value
    @record.assign_attributes @params
  end
end