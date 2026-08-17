module KitsHelper
  # The deactivate control for a kit. A kit that is still allocated to a storage location
  # cannot be deactivated, so the control stays a real disabled <button> -- the state reaches
  # assistive tech that way -- and the reason is given as sr-only text rather than a
  # hover-only tooltip, which a keyboard or touch user can never read.
  def deactivate_kit_button(kit, inventory)
    if kit.can_deactivate?(inventory)
      return essentials_action_button("Deactivate", deactivate_kit_path(kit), method: :put,
        variant: :ghost, size: :sm, icon: "bi-slash-circle",
        class: "deactivate-kit-button",
        confirm: confirm_deactivate_msg(kit.name))
    end

    button_to deactivate_kit_path(kit), method: :put, disabled: true,
      form_class: "inline-block",
      class: "#{essentials_button_classes(variant: :ghost, size: :sm)} deactivate-kit-button" do
      safe_join([
        tag.i(nil, class: "bi-slash-circle", aria: {hidden: true}),
        "Deactivate",
        tag.span(" — unavailable while a storage location still has kits.", class: "sr-only")
      ], " ")
    end
  end
end
