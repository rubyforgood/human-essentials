# Immutable result object for use in services
class Result < Data.define(:value, :error, :success)
  # Set default attribute values
  def initialize(value: nil, error: nil, success: false)
    super
  end

  alias_method :success?, :success
end
