class StaticController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  layout false

  def index
    redirect_to dashboard_url(current_user.organization) if current_user
  end

  def page
    # This allows for a flexible addition of static content
    # Anything under the url /pages/:name will render the file /app/views/static/[name].html.erb
    # Example: /pages/contact renders /app/views/static/contact.html.erb
    # Example2: /pages/index renders /app/views/static/index.html.erb, even when logged in
    render template: "static/#{params[:name]}"
  end
end
