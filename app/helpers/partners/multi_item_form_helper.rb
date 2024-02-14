module Partners
  module MultiItemFormHelper
    def remove_item_button(label, soft: false)
      link_to label, 'javascript:void(0)', class: 'btn btn-warning',
        data: { action: 'click->request-item#removeItem:prevent', remove_soft: soft ? true : false}
    end

    def add_item_button(label, container: ".fields", &block)
      content_tag :div do
        concat(
          link_to(label, "javascript:void(0)", class: "btn btn-outline-primary",
            data: {
              request_item_target: 'addButton', add_target: container,
              action: "click->request-item#addItem:prevent"
            })
        )
        concat(
          content_tag(:template, capture(&block), data: { request_item_target: 'addTemplate' })
        )
      end
    end
  end
end
