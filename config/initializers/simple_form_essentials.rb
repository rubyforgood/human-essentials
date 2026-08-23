# frozen_string_literal: true

# simple_form wrappers for the Ruby for Good design system (see design.md).
#
# These are now the ONLY wrappers: config/initializers/simple_form_bootstrap.rb is gone along
# with the rest of Bootstrap. `:essentials` is the default wrapper, so a plain
# `simple_form_for` produces design system markup and the `essentials_form_for` helper is a
# convenience rather than a requirement.
# Two things every input needs that simple_form does not give it here, added in one place
# rather than at 32 call sites.
#
# aria-required. The html5 component sets the `required` attribute from
# `required_field? && SimpleForm.browser_validations`, and browser_validations is off in this
# app -- deliberately, because the server is what validates and a browser bubble competing with
# a rendered error is two answers to one question. Turning it off also removed the only
# programmatic signal that a field is required: the label's `<abbr title="required">*</abbr>` is
# read by most screen readers as "star". aria-required restores the state without restoring the
# browser's own validation UI.
#
# aria-describedby. simple_form renders the error text into a <p> with no id, so nothing ties it
# to the field it belongs to -- a screen reader user tabbing into an invalid field hears the
# label and nothing else. The error is wrapped in a span carrying an id, and the input points at
# it. WCAG 3.3.1.
module EssentialsInputAria
  def input_html_options
    options = super
    options["aria-required"] = "true" if required_field?
    if has_errors? && self.options[:error] != false
      # uniq, because input_html_options is asked for more than once while an input renders and
      # a plain append produced the same id four times over.
      ids = options["aria-describedby"].to_s.split(/\s+/) << essentials_error_id
      options["aria-describedby"] = ids.uniq.reject(&:empty?).join(" ").presence
    end
    options
  end

  # The <p> the wrapper builds cannot take a per-field id -- wrapper options are static -- so the
  # id goes on a span inside it, which is what aria-describedby points at.
  def full_error(wrapper_options = nil)
    return unless options[:error] != false && has_errors?

    template.content_tag(:span, full_error_text, id: essentials_error_id)
  end

  def essentials_error_id
    [object_name, attribute_name, "error"].join("_").parameterize.underscore
  end
end

SimpleForm::Inputs::Base.prepend(EssentialsInputAria)

SimpleForm.setup do |config|
  input_classes = "block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm " \
                  "text-slate-900 placeholder:text-slate-400 shadow-sm " \
                  "focus:border-brand-500 focus:ring-2 focus:ring-brand-500/30 focus:outline-none " \
                  "disabled:cursor-not-allowed disabled:bg-slate-50 disabled:text-slate-500"

  # A select is not a text field: the browser draws an arrow inside the box, and `px-3` leaves it
  # 4px from the border with no way to move it. Every filter select in the app already turned the
  # native arrow off and painted its own, but simple_form's `wrapper_mappings` had no entry for
  # `select`, so 75 of the app's dropdowns fell through to the text-input wrapper and kept the
  # browser's. Same treatment for both now: `.select-chevron`, and `pr-10` so a long option does
  # not run underneath it.
  select_classes = input_classes.sub("px-3", "select-chevron pl-3 pr-10")

  invalid_classes = "border-rose-400 focus:border-rose-500 focus:ring-rose-500/30"
  label_classes = "block text-sm font-medium text-slate-700"
  hint_classes = "mt-1 block text-xs text-slate-500"
  # The glyph in `.field-error` is the danger signal; the sentence is body text. slate-700 rather
  # than rose-700 because the icon is what says "error" -- and it reads better, 10.35:1 on white
  # against 6.29:1, without turning a form with six problems into six lines of red. The hint
  # above uses slate-500 and no glyph, so the two are still told apart by more than hue.
  error_classes = "field-error mt-1 flex items-center text-xs font-medium text-slate-700"

  config.wrappers :essentials, tag: "div", class: "mb-4" do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: label_classes
    b.use :input, class: "mt-1.5 #{input_classes}", error_class: invalid_classes
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end

  # Identical to :essentials but for the input classes -- see `select_classes` above.
  config.wrappers :essentials_select, tag: "div", class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: label_classes
    b.use :input, class: "mt-1.5 #{select_classes}", error_class: invalid_classes
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end

  # A single checkbox: control and label sit on one line, label to the right.
  config.wrappers :essentials_boolean, tag: "div", class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly
    # py-0.5 on the label below, and min-h-6 here: a checkbox and its label are one target and
    # WCAG 2.5.8 asks for 24x24, but a size-4 box beside a text-sm label is 20px tall. The
    # padding goes on the label because the row wrapper's own box is not clickable.
    b.wrapper tag: "div", class: "flex min-h-6 items-start gap-2" do |ba|
      ba.use :input, class: "mt-0.5 h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-2 focus:ring-brand-500/30"
      ba.use :label, class: "py-0.5 text-sm text-slate-700"
    end
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end

  # Radio and checkbox collections get a real <fieldset>/<legend> so the group is named.
  config.wrappers :essentials_collection,
    tag: "fieldset",
    class: "mb-4",
    item_wrapper_class: "flex min-h-6 items-center gap-2",
    item_label_class: "py-0.5 text-sm text-slate-700" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: "legend", class: "#{label_classes} mb-1.5" do |ba|
      ba.use :label_text
    end
    b.use :input, class: "h-4 w-4 border-slate-300 text-brand-600 focus:ring-2 focus:ring-brand-500/30"
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end

  # A file input styled through its ::file-selector-button, so no JS label swap is needed
  # for the affordance itself.
  config.wrappers :essentials_file, tag: "div", class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: label_classes
    b.use :input, class: "mt-1.5 block w-full text-sm text-slate-600 " \
                         "file:mr-3 file:rounded-lg file:border-0 file:bg-brand-50 file:px-3 file:py-2 " \
                         "file:text-sm file:font-medium file:text-brand-700 hover:file:bg-brand-100"
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end
end

SimpleForm.setup do |config|
  # The design system wrapper is the default, so a form that does not opt in still gets it.
  config.default_wrapper = :essentials

  config.wrapper_mappings = {
    boolean: :essentials_boolean,
    check_boxes: :essentials_collection,
    radio_buttons: :essentials_collection,
    file: :essentials_file,
    select: :essentials_select
  }

  # Error notification and validation state, in design system colours. rose-600 is 4.51:1 on
  # white -- it passes, but only just -- so error TEXT uses -700 and -600 is only ever a
  # border.
  config.error_notification_class = "mb-5 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 text-sm font-medium text-rose-900"
  config.input_field_error_class = "border-rose-400 focus:border-rose-500 focus:ring-rose-500/30"
  config.input_field_valid_class = "border-emerald-400"
  config.boolean_label_class = "text-sm text-slate-700"
  config.boolean_style = :inline

  # simple_form adds `btn` to every button it renders. That is a Bootstrap class and is not
  # defined any more; the design system's classes are passed explicitly at the call site.
  config.button_class = nil
  config.label_text = ->(label, required, _explicit) { "#{label} #{required}" }
end
