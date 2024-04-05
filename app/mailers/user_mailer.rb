class UserMailer < ApplicationMailer
  def role_added(user, resource, roles)
    @user = user
    @resource = resource
    @roles = roles
    mail(to: user.email, subject: "#{"Role".pluralize(roles.size)} Added")
  end
end
