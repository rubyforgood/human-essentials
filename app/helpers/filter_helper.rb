module FilterHelper
  def filter_select(label: nil, scope:, collection:, key: :id, value: :name, selected: nil)
    sanitize_scope = scope.to_s.gsub("_", " ")
    label ||= "Filter #{sanitize_scope}"
    label_id = "filters_#{sanitize_scope}"
    label_tag(label_id, label) + collection_select(:filters, scope, collection || {}, key, value, { include_blank: true, selected: selected }, class: "form-control")
  end

  def filter_text(label: nil, scope:, selected: nil)
    sanitize_scope = scope.to_s.gsub("_", " ")
    label ||= "Filter #{sanitize_scope}"
    label_id = "filters_#{sanitize_scope}"
    label_tag(label_id, label) + text_field(:filters, scope, class: "form-control", value: selected)
  end

  def filter_checkbox(label: nil, scope:, selected: nil)
    label_tag do
      check_box_tag(scope, 1, selected) + label
    end
  end
end
