# Encapsulates some user-oriented business logic
module UsersHelper
  # Displays a gravatar, because people still use these, right?
  def gravatar_url(email, size)
    gravatar = Digest::MD5.hexdigest(email).downcase
    "http://gravatar.com/avatar/#{gravatar}.png?s=#{size}"
  end

  # A table-row action, so it takes the shared icon-button chrome. It was a hand-written
  # `btn btn-outline-primary btn-xs` -- three classes the stylesheet has not defined since
  # Bootstrap was removed -- which left a 14x20 target carrying `title` as its only accessible
  # name, and `alt` on a `<button>`, where that attribute means nothing. `essentials_action_button`
  # supplies the 24x24 target, the `aria-label` and the tooltip.
  #
  # It survived the whole migration because the class scan read `app/views` and not `app/helpers`.
  def reinvite_user_link(user)
    return unless user.reinvitable?

    essentials_action_button "Re-send invitation",
      resend_user_invitation_organization_path(user_id: user.id),
      method: :post, variant: :ghost, icon: "bi-envelope", icon_only: true
  end
end
