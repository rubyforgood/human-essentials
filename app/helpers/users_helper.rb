# Encapsulates some user-oriented business logic
module UsersHelper
  # Displays a gravatar, because people still use these, right?
  def gravatar_url(email, size)
    gravatar = Digest::MD5.hexdigest(email).downcase
    "http://gravatar.com/avatar/#{gravatar}.png?s=#{size}"
  end

  def reinvite_user_link(user)
    if user.reinvitable?
      link_to content_tag(:i, "", class: 'fa fa-envelope', alt: "Re-send invitation", title: "Re-send invitation"), resend_user_invitation_organization_path(user_id: user.id), method: :post
    end
  end

  def promote_to_org_admin_link(user)
    unless user.organization_admin?
      link_to content_tag(:i, "", class: 'fa fa-plus', alt: "Promote to admin", title: "Promote to admin"), promote_to_org_admin_organization_path(user_id: user.id), method: :post
    end
  end
end
