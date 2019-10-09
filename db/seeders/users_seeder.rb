class UserSeeder
  attr_accessor :organization, :user_params

  def self.seed(user_params, organization = nil)
    new(user_params, organization).seed
  end

  def initialize(user_params, organization = nil)
    @user_params = user_params
    @organization = organization
  end

  def seed
    create_user
  end

  private

  def create_user
    User.create(
      email: user_params[:email],
      password: 'password',
      password_confirmation: 'password',
      organization_admin: user_params[:organization_admin],
      super_admin: user_params[:super_admin],
      organization: organization
    )
  end
end
