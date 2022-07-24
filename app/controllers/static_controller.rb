# Provides a means to present static pages that still use the site layout
class StaticController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  skip_before_action :log_active_user

  layout false

  def index
    if current_user
      if current_user.partner.present?
        redirect_to partners_dashboard_path
      elsif current_user.organization.present?
        redirect_to dashboard_url(current_user.organization)
      elsif current_user.super_admin?
        redirect_to admin_dashboard_url if current_user.super_admin?
      end
    end
  end

  def register; end

  def page
    # This allows for a flexible addition of static content
    # Anything under the url /pages/:name will render the file /app/views/static/[name].html.erb
    # Example: /pages/contact renders /app/views/static/contact.html.erb
    # Example2: /pages/index renders /app/views/static/index.html.erb, even when logged in
    render template: "static/#{params[:name]}"
  end
end
