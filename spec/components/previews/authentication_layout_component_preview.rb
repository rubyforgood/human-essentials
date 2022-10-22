# frozen_string_literal: true

class AuthenticationLayoutComponentPreview < ViewComponent::Preview
  def account_request
    render(AuthenticationLayoutComponent.new(side_image_path: "onboarding-image.jpg")) do
      "You would be seeing account request form here"
    end
  end

  def authentication
    render(AuthenticationLayoutComponent.new(side_image_path: "auth-image.jpg")) do
      "You would be seeing login here"
    end
  end
end
