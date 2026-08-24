# Buttons and pseudo-buttons.
#
# The contract is unchanged from the AdminLTE version and its own comment still holds:
# "Anytime a button or pseudo-button are displayed, it should always be through one of these
# methods." What changed is the output -- design system classes and Bootstrap Icons rather
# than `btn btn-*` and Font Awesome, which draw nothing now.
#
# The `type:` and `size:` options are kept because ~60 call sites pass them. They are mapped
# onto the design system's variants rather than emitted as Bootstrap class names, so an
# existing call site keeps working and means the same thing.
module UiHelper
  # AdminLTE contextual name -> design system variant. The mapping preserves the meaning the
  # app already assigned to each colour: success creates, primary is the ordinary action,
  # info is read-only, warning needs attention, danger destroys.
  VARIANT_FOR_TYPE = {
    "primary" => :primary, "success" => :primary, "info" => :secondary,
    "secondary" => :secondary, "warning" => :secondary, "danger" => :danger,
    "outline-primary" => :ghost, "outline-dark" => :ghost, "outline-secondary" => :ghost,
    "light" => :ghost, "dark" => :secondary, "default" => :secondary
  }.freeze

  SIZE_FOR_LEGACY_SIZE = {
    "xs" => :sm, "sm" => :sm, "s" => :sm,
    "md" => :md, "m" => :md, "lg" => :md
  }.freeze

  # Font Awesome name -> Bootstrap Icon. An unmapped name falls back to a neutral glyph
  # rather than rendering an invisible element.
  ICON_FOR_FA = {
    "plus" => "bi-plus-lg", "trash" => "bi-trash", "ban" => "bi-slash-circle",
    "repeat" => "bi-arrow-counterclockwise", "check" => "bi-check2", "check-circle" => "bi-check-circle",
    "pencil-square-o" => "bi-pencil", "search" => "bi-eye", "download" => "bi-download",
    "upload" => "bi-upload", "print" => "bi-printer", "filter" => "bi-funnel",
    "envelope" => "bi-envelope", "floppy-o" => "bi-save", "sync" => "bi-arrow-repeat",
    "dot-circle-o" => "bi-record-circle", "sign-out" => "bi-box-arrow-right",
    "thumbs-o-up" => "bi-hand-thumbs-up", "undo" => "bi-arrow-counterclockwise",
    "eye" => "bi-eye", "user" => "bi-person", "users" => "bi-people", "close" => "bi-x-lg",
    "exclamation-circle" => "bi-exclamation-circle", "minus" => "bi-dash-lg"
  }.freeze

  def ui_variant(type) = VARIANT_FOR_TYPE.fetch(type.to_s, :secondary)

  def ui_size(size) = SIZE_FOR_LEGACY_SIZE.fetch(size.to_s, :md)

  def ui_icon(name)
    return nil if name.blank?
    tag.i(nil, class: ICON_FOR_FA.fetch(name.to_s, "bi-dot"), aria: {hidden: true})
  end

  # this method uses the form-input stimulus controller
  # to make this work you need to:
  #  - set data-controller="form-input" on the form element
  #  - container selector needs to be a unique css selector
  def add_element_button(label, container_selector:, **html_attrs, &block)
    default_html_attrs = {
      class: essentials_button_classes(variant: :secondary, size: :md),
      data: {form_input_target: "addButton",
             add_dest_selector: container_selector,
             action: "click->form-input#addItem:prevent"},
      role: "button",
      href: "javascript:void(0)"
    }
    attrs = default_html_attrs.merge(html_attrs)

    content_tag :div do
      concat(
        # link_to with a block takes the URL first; the href in attrs is what actually lands
        # on the element, and the anchor is inert (the Stimulus controller handles the click).
        link_to(attrs[:href] || "javascript:void(0)", attrs) do
          safe_join([ui_icon("plus"), label], " ")
        end
      )
      concat(content_tag(:template, capture(&block), data: {form_input_target: "addTemplate"}))
    end
  end

  # `icon_only:` renders the glyph alone and moves the label into `aria-label`. That is the
  # convention for a repeating row -- see design.md, Line item rows -- and it is deliberately
  # slate until hover, so a form with eight rows does not carry eight red marks down its edge.
  def remove_element_button(label, container_selector:, soft: false, icon_only: false, **html_attrs)
    default_class =
      if icon_only
        "#{EssentialsUiHelper::ICON_BUTTON_CLASSES} text-slate-500 " \
          "hover:bg-rose-50 hover:text-rose-700 focus-visible:outline-rose-600"
      else
        essentials_button_classes(variant: :ghost_danger, size: :sm)
      end

    default_html_attrs = {
      class: default_class,
      data: {
        action: "click->form-input#removeItem:prevent",
        remove_soft: soft ? true : false,
        remove_parent_selector: container_selector
      },
      href: "javascript:void(0)",
      role: "button"
    }
    default_html_attrs[:aria] = {label: label} if icon_only

    attrs = default_html_attrs.merge(html_attrs)

    link_to(attrs[:href] || "javascript:void(0)", attrs) do
      icon_only ? ui_icon("trash") : safe_join([ui_icon("trash"), label], " ")
    end
  end

  def delete_button_to(link, options = {})
    data = options[:no_confirm] ? {} : {data: {confirm: options[:confirm] || "Are you sure?"}}
    properties = {method: options[:method]&.to_sym || :delete, rel: "nofollow"}.merge(data)
    _link_to link, {icon: "trash", type: "danger", text: "Delete", size: "xs"}.merge(options), properties
  end

  def deactivate_button_to(link, options = {})
    data = options[:no_confirm] ? {} : {data: {confirm: options[:confirm] || "Are you sure?"}}
    properties = {id: options[:id], method: :put, rel: "nofollow"}.merge(data)
    _link_to link, {icon: "ban", type: "danger", text: "Deactivate", size: "xs"}.merge(options), properties
  end

  def reactivate_button_to(link, options = {})
    data = options[:no_confirm] ? {} : {data: {confirm: options[:confirm] || "Are you sure?"}}
    properties = {id: options[:id], method: :put, rel: "nofollow"}.merge(data)
    _link_to link, {icon: "repeat", type: "success", text: "Reactivate", size: "xs"}.merge(options), properties
  end

  def restore_button_to(link, options = {})
    data = options[:no_confirm] ? {} : {data: {confirm: options[:confirm] || "Are you sure?"}}
    properties = {rel: "nofollow", method: :patch}.merge(data)
    _link_to link, {icon: "repeat", type: "warning", text: "Restore", size: "xs"}.merge(options), properties
  end

  def update_button_to(link, options = {})
    properties = {rel: "nofollow", method: :patch}
    _link_to link, {icon: "check", type: "success", text: "Restore", size: "xs"}.merge(options), properties
  end

  def cancel_button_to(link, options = {})
    _link_to link, {icon: "ban", type: "outline-primary", text: "Cancel", size: "md"}.merge(options)
  end

  def clear_filter_button(options = {})
    cancel_button_to request.path, {size: "md", text: "Clear filters"}.merge(options)
  end

  def download_button_to(link, options = {})
    _link_to link, {icon: "download", type: "info", text: "Download", size: "md"}.merge(options)
  end

  def edit_button_to(link, options = {}, properties = {})
    _link_to link, {icon: "pencil-square-o", type: "primary", text: "Edit", size: "xs"}.merge(options), properties
  end

  # Used for keying off JavaScript.
  def js_button(options = {}, properties = {})
    _link_to "", {icon: "dot-circle-o", type: "outline-primary", text: "Set 'text' option", size: "md"}.merge(options), properties
  end

  # Opens a dialog. `target_id` keeps the AdminLTE "#someModal" form so call sites did not
  # have to change; the leading # is stripped and handed to the dialog Stimulus controller,
  # which calls showModal() on the matching native <dialog>.
  def modal_button_to(target_id, options = {}, properties = {})
    dialog_id = target_id.to_s.delete_prefix("#")
    classes = essentials_button_classes(
      variant: ui_variant(options[:type] || "secondary"),
      size: ui_size(options[:size]),
      extra: options[:class]
    )

    button_tag(type: "button", class: classes,
      data: {action: "click->dialog#open", dialog_id_param: dialog_id}.merge(properties[:data] || {})) do
      safe_join([ui_icon(options[:icon]), options[:text]].compact, " ")
    end
  end

  def new_button_to(link, options = {})
    _link_to link, {icon: "plus", type: "success", text: "New", size: "md"}.merge(options)
  end

  def print_button_to(link, options = {})
    _link_to link, {icon: "print", type: "outline-dark", text: "Print", size: "xs"}.merge(options)
  end

  # Generic Submit button for a form
  def submit_button(options = {}, data = {})
    disable_text = options[:disable_text] || "Saving"
    _button_to({text: "Save", icon: "floppy-o", type: "success", size: "md"}.merge(options),
      data: {disable_with: disable_text}.merge(data), name: options[:name] || "button")
  end

  # Like above, but POSTs to a URL instead of to a form
  def submit_button_to(link, options = {}, properties = {})
    properties = {method: options[:method]&.to_sym || :post, rel: "nofollow"}.merge(properties)
    _link_to link, {icon: "check-circle", type: "success", text: "Submit", size: "md"}.merge(options), properties
  end

  def view_button_to(link, options = {})
    _link_to link, {icon: "search", type: "info", text: "View", size: "xs"}.merge(options)
  end

  # A status, not a control: it is not focusable and does not look pressable.
  def status_label(text, icon, type)
    tone = {"success" => :success, "info" => :info, "warning" => :warning,
            "danger" => :danger, "secondary" => :neutral}.fetch(type.to_s, :neutral)
    essentials_status_pill(text, tone: tone, icon: ICON_FOR_FA.fetch(icon.to_s, "bi-dot"))
  end

  def invite_button_to(link, options = {}, properties = {})
    properties = {method: options[:method]&.to_sym || :post, rel: "nofollow",
                  data: {confirm: options[:confirm] || "Are you sure?"}}.merge(properties)
    _link_to link, {icon: "envelope", type: "warning", text: "Invite", size: "xs"}.merge(options), properties
  end

  def refresh_button_to(link, options = {}, properties = {})
    _link_to link, {icon: "sync", type: "info", text: "Refresh", size: "md"}.merge(options), properties
  end

  def _link_to(link, options = {}, properties = {})
    icon = options[:icon]
    text = options[:text]

    properties[:data] ||= {}
    properties[:data][:disable_with] ||= "Please wait..."
    properties[:data].merge!(options[:data]) if options[:data].present?
    properties[:title] = options[:title] if options[:title].present?

    enabled = options[:enabled].nil? || options[:enabled]

    klass = essentials_button_classes(
      variant: ui_variant(options[:type]),
      size: ui_size(options[:size]),
      extra: options[:class]
    )

    if properties[:method].blank? || properties[:method] == "get"
      # A link cannot be disabled -- it stays focusable and clickable by keyboard, and
      # announces nothing -- so an unavailable action is simply not rendered as a link.
      unless enabled
        return tag.span(class: "#{klass} cursor-not-allowed opacity-60", aria: {disabled: true}) do
          safe_join([ui_icon(icon), text].compact, " ")
        end
      end

      link_to link, properties.merge(class: klass) do
        safe_join([ui_icon(icon), text].compact, " ")
      end
    else
      button_to link, properties.merge(class: klass, form_class: "inline-block", disabled: !enabled) do
        safe_join([ui_icon(icon), text].compact, " ")
      end
    end
  end

  def _button_to(options = {}, properties = {})
    properties[:data] ||= {}
    properties[:data][:disable_with] ||= "Please wait..."

    klass = essentials_button_classes(
      variant: ui_variant(options[:type]),
      size: ui_size(options[:size]),
      extra: options[:class]
    )

    button_tag({type: options[:submit_type] || "submit", id: options[:id], class: klass}.merge(properties)) do
      safe_join([ui_icon(options[:icon]), options[:text]].compact, " ")
    end
  end

  def optional_data_text(field)
    if field.present?
      tag.span(field)
    else
      tag.span("Not provided", class: "italic text-slate-500")
    end
  end
end
