module Partners
  module MultiItemFormHelper
    def remove_item_button(label, soft: false)
      link_to label, 'javascript:void(0)', class: 'btn btn-warning', data: { remove_item: soft ? "soft" : nil }
    end

    def add_item_button(label, container: ".fields", &block)
      content_tag :div do
        concat(link_to(
          label,
          "javascript:void(0)",
          class: "btn btn-outline-primary",
          data: {
            request_item_target: 'addButton', action: "click->request-item#addItem:prevent",
            add_target: container
          }
        ))
        concat(
          content_tag(:template, capture(&block), data: { request_item_target: 'addTemplate' })
        )
      end
    end
  end
end
