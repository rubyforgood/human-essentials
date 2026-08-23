# Filter controls for an index page's filter bar.
#
# Each control gets a UUID-suffixed id and a matching label, so it is always named -- that was
# the good idea in the AdminLTE version and it is kept. What changed is the classes: Bootstrap's
# form-control draws nothing now.
#
# EssentialsUiHelper::FILTER_CONTROL_CLASSES is the single definition of what a filter control
# looks like; these methods and the design system's own essentials_filter_* wrappers share it.
module FilterHelper
  # `include_blank:` takes a string when the unfiltered view means something specific and the
  # user should be told what it is -- "Active", rather than an unexplained empty option.
  #
  # `hint:` explains a rule that an option label should not have to carry. Keeping labels short
  # and putting the explanation underneath is the ordinary advice -- an explanation inside an
  # option is re-read every time the list is opened, and it is invisible while the list is shut,
  # which is when someone is wondering what the current selection means.
  def filter_select(scope:, collection:, label: nil, key: :id, value: :name, selected: nil,
    include_blank: true, hint: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"
    hint_id = "#{id}_hint" if hint

    label_tag(id, label, class: EssentialsUiHelper::FILTER_LABEL_CLASSES) +
      collection_select(:filters, scope, collection || {}, key, value,
        {include_blank: include_blank, selected: selected},
        {class: EssentialsUiHelper::SELECT_CLASSES, id: id,
         aria: {describedby: hint_id}.compact}) +
      (hint ? tag.p(hint, id: hint_id, class: EssentialsUiHelper::FILTER_HINT_CLASSES) : "".html_safe)
  end

  def filter_text(scope:, label: nil, selected: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"

    label_tag(id, label, class: EssentialsUiHelper::FILTER_LABEL_CLASSES) +
      text_field(:filters, scope, class: EssentialsUiHelper::FILTER_CONTROL_CLASSES, id: id, value: selected)
  end

  # A single date, not a range -- `shared/date_range_picker` is the range control, and the two
  # are different questions: a range narrows a list of records to a window, this one asks what
  # the inventory looked like at a moment.
  #
  # Submits as a bare param rather than under `filters[...]`, for the same reason
  # `filter_checkbox` does. `Filterable#class_filter` walks that hash and calls
  # `public_send(key, value)` on the model, so every name in it has to be a real scope. A point
  # in time is not one, and putting it there would turn a filtered index into a NoMethodError.
  def filter_date(scope:, label: nil, selected: nil, min: nil, max: nil, hint: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"
    hint_id = "#{id}_hint" if hint

    label_tag(id, label, class: EssentialsUiHelper::FILTER_LABEL_CLASSES) +
      date_field_tag(scope, selected,
        class: EssentialsUiHelper::FILTER_CONTROL_CLASSES, id: id, min: min, max: max,
        aria: {describedby: hint_id}.compact) +
      (hint ? tag.p(hint, id: hint_id, class: EssentialsUiHelper::FILTER_HINT_CLASSES) : "".html_safe)
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
