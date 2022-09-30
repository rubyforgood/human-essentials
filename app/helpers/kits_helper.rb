module KitsHelper
  def deactivate_kit_button(kit)
    options = {class: "deactivate-kit-button"}
    span_options = {}
    unless kit.can_deactivate?
      msg = "Cannot deactivate since kit has current allocations - please deallocate all storage locations first!"
      options[:enabled] = false
      span_options = {title: msg, class: "tooltip-target"}
    end
    tag.span(span_options) do
      deactivate_button_to(deactivate_kit_path(kit),
        options.merge({text: "Deactivate",
          confirm: confirm_deactivate_msg(kit.name), size: "m"}))
    end
  end
end
