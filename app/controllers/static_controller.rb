# The public site: the landing page at / and the privacy policy. Signed out, on a layout and a
# stylesheet of their own (layouts/landing, landing.css) rather than the design system's --
# see design.md, "The public site".
class StaticController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!
  skip_before_action :require_organization
  skip_before_action :log_active_user

  layout "landing"

  # The landing page's map. A helper rather than an instance variable set in `index`, because
  # `page` can render the same template.
  helper_method :bank_map

  def index
    redirect_to dashboard_path_from_current_role if current_user
  end

  def register; end

  def page
    # This allows for a flexible addition of static content
    # Anything under the url /pages/:name will render the file /app/views/static/[name].html.erb
    # Example: /pages/contact renders /app/views/static/contact.html.erb
    # Example2: /pages/index renders /app/views/static/index.html.erb, even when logged in
    render template: "static/#{params[:name]}"
  end

  private

  def bank_map
    @bank_map ||= BankMapQuery.call
  end
end
