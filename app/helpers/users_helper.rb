# Encapsulates some user-oriented business logic
module UsersHelper
  # Displays a gravatar, because people still use these, right?
  def gravatar_url(email, size)
    gravatar = Digest::MD5.hexdigest(email).downcase
    "http://gravatar.com/avatar/#{gravatar}.png?s=#{size}"
  end

  def reinvite_user_link(user)
    if user.reinvitable?
      button_to resend_user_invitation_organization_path(user_id: user.id), class: "btn btn-outline-primary btn-xs", data: {disable_with: "Please wait..."}, alt: "Re-send invitation", title: "Re-send invitation" do
        fa_icon "envelope"
      end
    end
  end
end
