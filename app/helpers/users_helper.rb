module UsersHelper
  def reinvite_user_link(user)
    if user.reinvitable?
      link_to content_tag(:i, "", class: 'fa fa-envelope', alt: "Re-send invitation", title: "Re-send invitation"), resend_user_invitation_organization_path(user_id: user.id), method: :post
    end
  end
end
