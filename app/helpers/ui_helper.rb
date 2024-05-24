# Creates common methods that we can use throughout the app to ensure that buttons display consistently, which
# hopefully creates a better UX overall. Anytime a button or pseudo-button are displayed, it should *always*
# be through one of these methods. Most of these can be adapted to display in different ways, but those alterations
# will be evident in the source code that it's deviating from the standard.
module UiHelper
  # this method uses the form-input stimulus controller
  # to make this work you need to:
  #  - set data-controller="form-input" on the form element
  #  - container selector needs to a unique css selector
  def add_element_button(label, container_selector:, **html_attrs, &block)
    default_html_attrs = {
      class: "btn btn-md btn-primary",
      data: { form_input_target: 'addButton',
              add_dest_selector: container_selector,
              action: "click->form-input#addItem:prevent" },
      role: "button",
      href: "javascript:void(0)"
    }
    content_tag :div do
      concat(
        link_to(label, default_html_attrs.merge(html_attrs)) do
          fa_icon "plus", text: label
        end
      )
      concat(
        content_tag(:template, capture(&block), data: { form_input_target: 'addTemplate' })
      )
    end
  end

  # this method uses the form-input stimulus controller
  # to make this work you need to:
  #  - set data-controller="form-input" on the form element
  #  - container selector
  def remove_element_button(label, container_selector:, soft: false, **html_attrs)
    default_html_attrs = {
      class: "btn btn-md btn-danger",
      data: {
        action: 'click->form-input#removeItem:prevent',
        remove_soft: soft ? true : false,
        remove_parent_selector: container_selector
      },
      href: "javascript:void(0)",
      role: "button",
      style: "width: 100px;"
    }

    link_to(label, default_html_attrs.merge(html_attrs)) do
      fa_icon "trash", text: label
    end
  end

  def delete_button_to(link, options = {})
    # Delete has a few extra options we have to consider to ensure the button works right
    data = options[:no_confirm] ? {} : { data: { confirm: options[:confirm] || "Are you sure?" } }
    properties = { method: options[:method]&.to_sym || :delete, rel: "nofollow" }.merge(data)
    _link_to link, { icon: "trash", type: "danger", text: "Delete", size: "xs" }.merge(options), properties
  end

  def deactivate_button_to(link, options = {})
    data = options[:no_confirm] ? {} : { data: { confirm: options[:confirm] || "Are you sure?" } }
    properties = { id: options[:id], method: :put, rel: "nofollow" }.merge(data)
    _link_to link, { icon: "ban", type: "danger", text: "Deactivate", size: "xs" }.merge(options), properties
  end

  def reactivate_button_to(link, options = {})
    data = options[:no_confirm] ? {} : { data: { confirm: options[:confirm] || "Are you sure?" } }
    properties = { id: options[:id], method: :put, rel: "nofollow" }.merge(data)
    _link_to link, { icon: "repeat", type: "success", text: "Reactivate", size: "xs" }.merge(options), properties
  end

  def restore_button_to(link, options = {})
    data = options[:no_confirm] ? {} : { data: { confirm: options[:confirm] || "Are you sure?" } }
    properties = { rel: "nofollow", method: :patch }.merge(data)
    _link_to link, { icon: "repeat", type: "warning", text: "Restore", size: "xs" }.merge(options), properties
  end

  def update_button_to(link, options = {})
    properties = { rel: "nofollow", method: :patch }
    _link_to link, { icon: "check", type: "success", text: "Restore", size: "xs" }.merge(options), properties
  end

  def dropdown_button(id, options = {})
    options[:type] = (options[:type] || "primary").prepend("btn-dropdown btn-")
    options[:id] = id
    additional_properties = {
      data: {
        "bs-toggle": "dropdown"
      },
      "aria-haspopup": true,
      "aria-expanded": true
    }

    _button_to({ submit_type: "button", text: "Set the 'text' property", size: "md", icon: "caret-down" }.merge(options), additional_properties)
  end

  def cancel_button_to(link, options = {})
    _link_to link, { icon: "ban", type: "outline-primary", text: "Cancel", size: "md" }.merge(options)
  end

  def clear_filter_button(options = {})
    cancel_button_to request.path, { size: "md", text: "Clear Filters" }.merge(options)
  end

  def download_button_to(link, options = {})
    _link_to link, { icon: "download", type: "info", text: "Download", size: "md" }.merge(options)
  end

  def edit_button_to(link, options = {}, properties = {})
    _link_to link, { icon: "pencil-square-o", type: "primary", text: "Edit", size: "xs" }.merge(options), properties
  end

  def filter_button(options = {})
    _button_to({ icon: "filter", type: "primary", text: "Filter", size: "md" }.merge(options))
  end

  # Used for keying off JavaScript.
  def js_button(options = {}, properties = {})
    _link_to '', { icon: "dot-circle-o", type: "outline-primary", text: "Set 'text' option", size: "md" }.merge(options), properties
  end

  def modal_button_to(target_id, options = {})
    properties = { data: { "bs-toggle": "modal" } }
    _link_to target_id, { icon: "dot-circle-o", type: "outline-primary", text: "Set 'text' option", size: "md" }.merge(options), properties
  end

  def new_button_to(link, options = {})
    _link_to link, { icon: "plus", type: "success", text: "New", size: "md" }.merge(options)
  end

  def print_button_to(link, options = {})
    _link_to link, { icon: "print", type: "outline-dark", text: "Print", size: "xs" }.merge(options)
  end

  # Generic Submit button for a form
  def submit_button(options = {}, data = {})
    disable_text = options[:disable_text] || "Saving"
    _button_to({ text: "Save", icon: "floppy-o", type: "success", align: "pull-right" }.merge(options), data: { disable_with: disable_text }.merge(data), name: options[:name] || 'button')
  end

  # Like above, but POSTs to a URL instead of to a form
  def submit_button_to(link, options = {}, properties = {})
    properties = { method: options[:method]&.to_sym || :post, rel: "nofollow" }.merge(properties)
    _link_to link, { icon: "check-circle", type: "success", text: "Submit", size: "lg" }.merge(options), properties
  end

  def view_button_to(link, options = {})
    _link_to link, { icon: "search", type: "info", text: "View", size: "xs" }.merge(options)
  end

  def invite_button_to(link, options = {}, properties = {})
    properties = { method: options[:method]&.to_sym || :post, rel: "nofollow", data: { confirm: options[:confirm] || "Are you sure?" } }.merge(properties)
    _link_to link, { icon: "envelope", type: "warning", text: "Invite", size: "xs" }.merge(options), properties
  end

  def refresh_button_to(link, options = {}, properties = {})
    _link_to link, { icon: "sync", type: "info", text: "Refresh", size: "md" }.merge(options), properties
  end

  def _link_to(link, options = {}, properties = {})
    icon = options[:icon]
    text = options[:text]
    size = options[:size]
    type = options[:type]
    if options[:data].present?
      properties[:data] ||= {}
      properties[:data].merge!(options[:data])
    end
    properties[:title] = options[:title] if options[:title].present?

    # user sparingly.
    center = options[:center].present? ? "center-block" : ""

    disabled = (options[:enabled] || options[:enabled].nil?) ? "" : "disabled"

    klass = "#{options[:class] || ""} btn btn-#{type} btn-#{size} #{center} #{disabled}"

    link_to link, properties.merge(class: klass) do
      fa_icon icon, text: text
    end
  end

  def _button_to(options = {}, other_properties = {})
    submit_type = options[:submit_type] || "submit"
    id = options[:id]
    type = options[:type]
    size = options[:size]
    icon = options[:icon]
    text = options[:text]
    align = options[:align]

    button_tag({ type: submit_type, id: id, class: "btn btn-#{type} btn-#{size} #{align}" }.merge(other_properties)) do
      fa_icon icon, text: text
    end
  end

  def optional_data_text(field)
    if field.present?
      tag.span(field)
    else
      tag.span("Not-Provided", class: "text-muted font-weight-light")
    end
  end
end
