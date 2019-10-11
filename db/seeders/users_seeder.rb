class UsersSeeder
  attr_accessor :pdx_org, :sf_org

  def self.seed(pdx_org, sf_org)
    new(pdx_org, sf_org).seed
  end

  def initialize(pdx_org, sf_org)
    @pdx_org = pdx_org
    @sf_org = sf_org
  end

  def seed
    users.map { |user| create_user(user) }
  end

  private

  def users
    [
      { email: 'superadmin@example.com', organization_admin: false, super_admin: true },
      { email: 'org_admin1@example.com', organization_admin: true, organization: pdx_org },
      { email: 'org_admin2@example.com', organization_admin: true, organization: sf_org },
      { email: 'user_1@example.com', organization_admin: false, organization: pdx_org },
      { email: 'user_2@example.com', organization_admin: false, organization: sf_org },
      { email: 'test@example.com', organization_admin: false, super_admin: true, organization: pdx_org },
      { email: 'test2@example.com', organization_admin: true, organization: pdx_org }
    ]
  end

  def create_user(user_params)
    User.create(
      email: user_params[:email],
      password: 'password',
      password_confirmation: 'password',
      organization_admin: user_params[:organization_admin],
      super_admin: user_params[:super_admin],
      organization: user_params[:organization]
    )
  end
end
