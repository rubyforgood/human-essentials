# Icons.
#
# The helper keeps its name and signature -- `fa_icon "envelope", text: "Email"` -- because
# it is called from ~40 places, but it emits Bootstrap Icons. Font Awesome is not loaded any
# more, so an `fa fa-*` class renders an empty element: no glyph, no error, just a gap.
#
# An icon rendered here is decorative: it always sits beside its own text, or beside a value
# it merely marks. It is aria-hidden, and a control that has ONLY an icon must carry its own
# aria-label at the call site.
module IconHelper
  # Font Awesome 4/5 name -> Bootstrap Icon. The keys are the names already in the codebase.
  BOOTSTRAP_ICON = {
    "address-card-o" => "person-vcard", "angle-left" => "chevron-left", "angle-right" => "chevron-right",
    "ban" => "slash-circle", "barcode" => "upc-scan", "bars" => "list", "bell-o" => "bell",
    "building" => "building", "building-o" => "buildings", "calendar" => "calendar",
    "calendar-o" => "calendar", "camera-retro" => "camera", "caret-down" => "chevron-down",
    "check" => "check2", "check-circle" => "check-circle", "child" => "person-arms-up",
    "chevron-right" => "chevron-right", "circle-o" => "circle", "clock" => "clock",
    "clock-o" => "clock", "close" => "x-lg", "cog" => "gear", "cogs" => "sliders",
    "dashboard" => "speedometer2", "dollar" => "currency-dollar", "dot-circle-o" => "record-circle",
    "download" => "download", "edit" => "pencil", "envelope" => "envelope", "external-link" => "box-arrow-up-right",
    "eye" => "eye", "female" => "person", "file-text" => "file-text", "file-text-o" => "file-text",
    "filter" => "funnel", "floppy-o" => "save", "globe" => "globe", "gratipay" => "gift",
    "group" => "people", "hand-o-right" => "hand-index", "heart" => "heart-fill", "home" => "house",
    "inbox" => "inbox", "institution" => "bank", "laptop" => "laptop", "list" => "list-ul",
    "lock" => "lock", "map" => "geo-alt", "map-marker" => "geo-alt", "minus" => "dash-lg",
    "money" => "cash", "paper-plane" => "send", "pencil" => "pencil", "pencil-square-o" => "pencil-square",
    "phone" => "telephone", "pie-chart" => "pie-chart", "plus" => "plus-lg", "print" => "printer",
    "question-circle" => "question-circle", "repeat" => "arrow-repeat", "search" => "search",
    "shopping-cart" => "cart", "sign-out" => "box-arrow-right", "sitemap" => "diagram-3",
    "suitcase" => "briefcase", "sync" => "arrow-repeat", "tachometer-alt" => "speedometer2",
    "tag" => "tag", "tasks" => "list-check", "th" => "grid", "thumbs-o-up" => "hand-thumbs-up",
    "times" => "x-lg", "trash" => "trash", "undo" => "arrow-counterclockwise", "upload" => "upload",
    "usd" => "currency-dollar", "user" => "person", "user-friends" => "people", "users" => "people",
    "warning" => "exclamation-triangle", "exclamation-circle" => "exclamation-circle", "file" => "file-earmark"
  }.freeze

  # Examples
  #
  #   fa_icon "camera-retro"
  #   # => <i class="bi-camera" aria-hidden="true"></i>
  #
  #   fa_icon "camera-retro", text: "Take a photo"
  #   # => <i class="bi-camera" aria-hidden="true"></i> Take a photo
  #
  #   fa_icon "chevron-right", text: "Get started", right: true
  #   # => Get started <i class="bi-chevron-right" aria-hidden="true"></i>
  def fa_icon(names = "flag", original_options = {})
    options = original_options.deep_dup
    text = options.delete(:text)
    right_icon = options.delete(:right)

    classes = ["bi-#{Private.bootstrap_name(names)}"]
    classes.concat Array(options.delete(:class))

    # Decorative by definition: the icon repeats its own label or marks a value.
    options[:aria] = {hidden: true}.merge(options[:aria] || {})

    icon = tag.i(nil, **options, class: classes)
    Private.icon_join(icon, text, right_icon)
  end

  module Private
    extend ActionView::Helpers::OutputSafetyHelper

    # A Font Awesome name may carry size/style modifiers ("spinner spin lg"); only the first
    # token names the glyph. An unmapped name falls back to a neutral dot rather than an
    # element that draws nothing.
    def self.bootstrap_name(names)
      first = array_value(names).first.to_s
      BOOTSTRAP_ICON.fetch(first, "dot")
    end

    def self.icon_join(icon, text, reverse_order = false)
      return icon if text.blank?
      elements = [icon, ERB::Util.html_escape(text)]
      elements.reverse! if reverse_order
      safe_join(elements, " ")
    end

    def self.array_value(value = [])
      value.is_a?(Array) ? value : value.to_s.split(/\s+/)
    end
  end
end
