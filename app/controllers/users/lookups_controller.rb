class Users::LookupsController < ApplicationController
  skip_before_action :authorize_user
  skip_before_action :authenticate_user!

  def new
    @resource = UserLookup.new
    render :new, layout: "devise"
  end

  # TODO: flash message from logout is showing up residually on bank/partner login pages
  def create
    email, selection = params[:user].values_at(:email, :organization)

    @user = User.find_by(email: email)
    @partner_user = Partners::User.find_by(email: email)

    render_selected_login(selection) ||
      render_options ||
      render_bank_login ||
      render_partner_login # TODO: handle email not found
  end

  private

  def render_selected_login(selection)
    case selection
    when "Bank" then render_bank_login
    when "Partner" then render_partner_login
    else false
    end
  end

  def render_options
    if @user && @partner_user
      resource.email = @user.email
      resource.organization = "Bank"
      resource.organizations = [
        [@user.organization.name, "Bank"],
        [@partner_user.partner.name, "Partner"]
      ]
      render :new, layout: "devise"
    end
  end

  def render_bank_login
    if @user
      resource.email = @user.email
      @resource_name = "user"
      render "users/sessions/new", layout: "devise"
    end
  end

  def render_partner_login
    if @partner_user
      resource.email = @partner_user.email
      @resource_name = "partner_user"
      render "partner_users/sessions/new", layout: "devise_partner_users"
    end
  end

  class UserLookup
    attr_accessor :email, :organization, :organizations
  end

  # The methods below essentially ducktype this controller so that it looks
  # like a devise controller to devise-y templates, such as shared/links

  def resource
    @resource ||= UserLookup.new
  end

  def resource_name
    @resource_name ||= "user"
  end

  def devise_mapping
    @devise_mapping ||= DeviseMappingShunt.new
  end

  helper_method :resource, :resource_name, :devise_mapping

  class DeviseMappingShunt
    def registerable?
      true
    end

    def recoverable?
      true
    end

    def confirmable?
      false
    end

    def lockable?
      false
    end

    def omniauthable?
      false
    end
  end
end
