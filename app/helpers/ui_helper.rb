# Creates common methods that we can use throughout the app to ensure that buttons display consistently, which
# hopefully creates a better UX overall. Anytime a button or pseudo-button are displayed, it should *always*
# be through one of these methods. Most of these can be adapted to display in different ways, but those alterations
# will be evident in the source code that it's deviating from the standard.
module UiHelper
  def add_line_item_button(form, node, options = {})
    text = options[:text] || "Add another item"
    size = options[:size] || "md"
    type = options[:type] || "primary"
    partial = options[:partial] || "line_items/line_item_fields"
    link_to_add_association form, :line_items,
                            data: {
                              association_insertion_node: node,
                              association_insertion_method: "append"
                            }, id: "__add_line_item", class: "btn btn-#{size} btn-#{type}", style: "margin-top: 1rem;", partial: partial do
      fa_icon "plus", text: text
    end
  end

  def delete_line_item_button(form, options = {})
    text = options[:text] || "Remove"
    size = options[:text] || "sm"
    type = options[:type] || "danger"

    link_to_remove_association form, class: "btn btn-#{size} btn-#{type}" do
      fa_icon "trash", text: text
    end
  end

  def delete_button_to(link, options = {})
    # Delete has a few extra options we have to consider to ensure the button works right
    data = options[:no_confirm] ? {} : { data: { confirm: options[:confirm] || "Are you sure?" } }
    properties = { method: options[:method]&.to_sym || :delete, rel: "nofollow" }.merge(data)
    _link_to link, { icon: "trash", type: "danger", text: "Delete", size: "xs" }.merge(options), properties
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
        toggle: "dropdown"
      },
      'aria-haspopup': true,
      'aria-expanded': true
    }

    _button_to({ submit_type: "button", text: "Set the 'text' property", size: "md", icon: "caret-down" }.merge(options), additional_properties)
  end

  def cancel_button_to(link, options = {})
    _link_to link, { icon: "ban", type: "outline-primary", text: "Cancel", size: "md" }.merge(options)
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

  def modal_button_to(target_id, options = {})
    properties = { data: { toggle: "modal" } }
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
    _button_to({ text: "Save", icon: "floppy-o", type: "success", align: "pull-right" }.merge(options), data: { disable_text: disable_text }.merge(data), name: options[:name] || 'button')
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

  def _link_to(link, options = {}, properties = {})
    icon = options[:icon]
    text = options[:text]
    size = options[:size]
    type = options[:type]
    # user sparingly.
    center = options[:center].present? ? "center-block" : ""

    link_to link, properties.merge(class: "btn btn-#{type} btn-#{size} #{center}") do
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
end
