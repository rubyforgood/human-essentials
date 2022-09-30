module FilterHelper
  def filter_select(label: nil, scope:, collection:, key: :id, value: :name, selected: nil)
    label ||= "Filter #{scope.to_s.gsub(/_/, ' ')}"
    label_tag(label) + collection_select(:filters, scope, collection || {}, key, value, { include_blank: true, selected: selected }, class: "form-control")
  end

  def filter_text(label: nil, scope:, selected: nil)
    label ||= "Filter #{scope.to_s.gsub(/_/, ' ')}"
    label_tag(label) + text_field(:filters, scope, class: "form-control", value: selected)
  end

  def filter_checkbox(label: nil, scope:, selected: nil)
    label_tag do
      check_box_tag(scope, 1, selected) + label
    end
  end
end
