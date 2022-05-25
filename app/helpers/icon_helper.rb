# Vendored/copied from the font_awesome gem.
module IconHelper
  # Creates an icon tag given an icon name and possible icon
  # modifiers.
  #
  # Examples
  #
  #   fa_icon "camera-retro"
  #   # => <i class="fa fa-camera-retro"></i>
  #
  #   fa_icon "camera-retro", text: "Take a photo"
  #   # => <i class="fa fa-camera-retro"></i> Take a photo
  #   fa_icon "chevron-right", text: "Get started", right: true
  #   # => Get started <i class="fa fa-chevron-right"></i>
  #
  #   fa_icon "camera-retro 2x"
  #   # => <i class="fa fa-camera-retro fa-2x"></i>
  #   fa_icon ["camera-retro", "4x"]
  #   # => <i class="fa fa-camera-retro fa-4x"></i>
  #   fa_icon "spinner spin lg"
  #   # => <i class="fa fa-spinner fa-spin fa-lg">
  #
  #   fa_icon "quote-left 4x", class: "pull-left"
  #   # => <i class="fa fa-quote-left fa-4x pull-left"></i>
  #
  #   fa_icon "user", data: { id: 123 }
  #   # => <i class="fa fa-user" data-id="123"></i>
  #
  #   content_tag(:li, fa_icon("check li", text: "Bulleted list item"))
  #   # => <li><i class="fa fa-check fa-li"></i> Bulleted list item</li>
  def fa_icon(names = "flag", original_options = {})
    options = original_options.deep_dup
    classes = ["fa"]
    classes.concat Private.icon_names(names)
    classes.concat Array(options.delete(:class))
    text = options.delete(:text)
    right_icon = options.delete(:right)
    icon = content_tag(:i, nil, options.merge(class: classes)) # rubocop:disable Rails/ContentTag
    Private.icon_join(icon, text, right_icon)
  end

  module Private
    extend ActionView::Helpers::OutputSafetyHelper

    def self.icon_join(icon, text, reverse_order = false)
      return icon if text.blank?
      elements = [icon, ERB::Util.html_escape(text)]
      elements.reverse! if reverse_order
      safe_join(elements, " ")
    end

    def self.icon_names(names = [])
      array_value(names).map { |n| "fa-#{n}" }
    end

    def self.array_value(value = [])
      value.is_a?(Array) ? value : value.to_s.split(/\s+/)
    end
  end
end
