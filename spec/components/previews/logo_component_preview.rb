# frozen_string_literal: true

class LogoComponentPreview < ViewComponent::Preview
  def default
    render(LogoComponent.new)
  end
end
