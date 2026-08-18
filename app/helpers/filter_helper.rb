# Filter controls for an index page's filter bar.
#
# Each control gets a UUID-suffixed id and a matching label, so it is always named -- that was
# the good idea in the AdminLTE version and it is kept. What changed is the classes: Bootstrap's
# form-control draws nothing now.
#
# EssentialsUiHelper::FILTER_CONTROL_CLASSES is the single definition of what a filter control
# looks like; these methods and the design system's own essentials_filter_* wrappers share it.
module FilterHelper
  def filter_select(scope:, collection:, label: nil, key: :id, value: :name, selected: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"

    label_tag(id, label, class: EssentialsUiHelper::FILTER_LABEL_CLASSES) +
      collection_select(:filters, scope, collection || {}, key, value,
        {include_blank: true, selected: selected},
        {class: EssentialsUiHelper::FILTER_CONTROL_CLASSES, id: id})
  end

  def filter_text(scope:, label: nil, selected: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"

    label_tag(id, label, class: EssentialsUiHelper::FILTER_LABEL_CLASSES) +
      text_field(:filters, scope, class: EssentialsUiHelper::FILTER_CONTROL_CLASSES, id: id, value: selected)
  end

  def filter_checkbox(label:, scope:, selected: nil)
    id = "filters_#{scope}_#{SecureRandom.uuid}"

    tag.div(class: "flex items-center gap-2") do
      concat check_box_tag(scope, 1, selected, id: id,
        class: "h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-2 focus:ring-brand-500/30")
      concat label_tag(id, label, class: "text-sm text-slate-700")
    end
  end
end
