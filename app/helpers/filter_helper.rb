module FilterHelper
  def filter_select(label: nil, scope:, collection:, key: :id, value: :name, selected: nil)
    sanitize_scope = scope.to_s.gsub("_", " ")
    label ||= "Filter #{sanitize_scope}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"
    label_tag(id, label) + collection_select(:filters, scope, collection || {}, key, value, { include_blank: true, selected: selected }, {class: "form-control", id: id})
  end

  def filter_text(label: nil, scope:, selected: nil)
    sanitize_scope = scope.to_s.gsub("_", " ")
    label ||= "Filter #{sanitize_scope}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"
    label_tag(id, label) + text_field(:filters, scope, class: "form-control", id: id, value: selected)
  end

  def filter_checkbox(label: nil, scope:, selected: nil)
    label_tag do
      check_box_tag(scope, 1, selected) + label
    end
  end
end
