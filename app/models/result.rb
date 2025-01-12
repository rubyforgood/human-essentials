# Immutable result object for use in services
class Result < Data.define(:value, :error)
  # Set default attribute values
  def initialize(value: nil, error: nil)
    super
  end

  def success? = error.nil?
end
