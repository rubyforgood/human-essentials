# frozen_string_literal: true

class AuthenticationLayoutComponent < ViewComponent::Base
  def initialize(side_image_path:)
    @side_image_path = side_image_path
  end

end
