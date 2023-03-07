# Service inspired and modded from
# https://github.com/ruby-i18n/i18n/blob/76c677a783f2d6b77e24e8c0bf842f72859cad53/lib/i18n/interpolate/ruby.rb
class TextInterpolatorService
  include ServiceObjectErrorsMixin

  INTERPOLATION_PATTERN = Regexp.union([
    /%\{([\w]+)\}/, # matches placeholders like "%{foo}
  ].freeze)

  attr_accessor :text, :values

  def initialize(text, values = {})
    @text = text
    @values = values.try(:with_indifferent_access) || {}
  end

  def call
    return text if text.blank?

    text.gsub(INTERPOLATION_PATTERN) do |match|
      if match == '%%'
        '%'
      else
        key = ($1 || $2 || match.tr("%{}", "")).to_sym
        value = values[key] if values.key?(key)
        ($3) ? format("%#{$3}", value) : value
      end
    end
  end
end
