class ConsolidatedLoginDirector
  attr_reader :email, :organization, :organizations, :render, :layout, :resource_name

  def initialize
    @render = :new
    @layout = "devise"
    @resource_name = "user"
  end

  def lookup(params)
    email, selection = params.values_at("email", "organization")

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
      @organization = "Bank"
      @organizations = [
        [@user.organization.name, "Bank"],
        [@partner_user.partner.name, "Partner"]
      ]

      @email = @user.email
      @resource_name = "user"
      @render = :new
      @layout = "devise"
    end
  end

  def render_bank_login
    if @user
      @email = @user.email
      @resource_name = "user"
      @render = "users/sessions/new"
      @layout = "devise"
    end
  end

  def render_partner_login
    if @partner_user
      @email = @partner_user.email
      @resource_name = "partner_user"
      @render = "partner_users/sessions/new"
      @layout = "devise_partner_users"
    end
  end
end
