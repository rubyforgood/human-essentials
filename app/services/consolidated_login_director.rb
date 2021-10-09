class ConsolidatedLoginDirector
  include ActiveModel::Validations

  attr_reader :email, :organization, :organizations, :render, :layout, :resource_name

  def initialize
    @render = :new
    @layout = "devise_consolidated_login"
    @resource_name = "user"
  end

  def lookup(params)
    email, selection = params.values_at("email", "organization")

    @user = User.find_by(email: email)
    @partner_user = Partners::User.find_by(email: email)

    selected_login(selection) ||
      options ||
      bank_login ||
      partner_login ||
      email_not_found(email)
  end

  private

  def selected_login(selection)
    case selection
    when "Bank" then bank_login
    when "Partner" then partner_login
    else false
    end
  end

  def options
    if @user && @partner_user
      @organization = "Bank"
      @organizations = [
        [@user.organization.name, "Bank"],
        [@partner_user.partner.name, "Partner"]
      ]

      @email = @user.email
      @resource_name = "user"
      @render = :new
      @layout = "devise_consolidated_login"
    end
  end

  def bank_login
    if @user
      @email = @user.email
      @resource_name = "user"
      @render = "users/sessions/new"
      @layout = "devise"
    end
  end

  def partner_login
    if @partner_user
      @email = @partner_user.email
      @resource_name = "partner_user"
      @render = "partner_users/sessions/new"
      @layout = "devise_partner_users"
    end
  end

  def email_not_found(email)
    fail if @user || @partner_user # this method shouldn't be called if either are present

    errors.add :email, "not found"
    @email = email
  end
end
