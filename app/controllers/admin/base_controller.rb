class Admin::BaseController < ApplicationController
  layout 'admin'
  respond_to :html, :json, :csv

  before_action :authenticate_user!
  before_action :authenticate_admin_user!
  before_action do
    add_crumb 'Admin', admin_root_path
    set_meta(title: "#{ENV['APP_NAME']} Admin")
    @admin_page_title = 'Admin'
  end

  def index; end

  private

  def authenticate_admin_user!
    redirect_to root_path unless current_user.admin?
  end
end
