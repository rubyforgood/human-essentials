module Partners
  module MultiItemFormHelper
    def remove_item_button(label, soft: false)
      link_to label, 'javascript:void(0)', class: 'btn btn-warning', data: { remove_item: soft ? "soft" : nil }
    end

    def add_item_button(label, container: ".fields", &block)
      link_to(
        label, "javascript:void(0)",
        class: "btn btn-outline-primary",
        data: { add_target: container, add_template: capture(&block) }
      )
    end
  end
end
