# frozen_string_literal: true

# simple_form wrappers for the Ruby for Good design system (see design.md).
#
# These are now the ONLY wrappers: config/initializers/simple_form_bootstrap.rb is gone along
# with the rest of Bootstrap. `:essentials` is the default wrapper, so a plain
# `simple_form_for` produces design system markup and the `essentials_form_for` helper is a
# convenience rather than a requirement.
SimpleForm.setup do |config|
  input_classes = "block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm " \
                  "text-slate-900 placeholder:text-slate-400 shadow-sm " \
                  "focus:border-brand-500 focus:ring-2 focus:ring-brand-500/30 focus:outline-none " \
                  "disabled:cursor-not-allowed disabled:bg-slate-50 disabled:text-slate-500"

  invalid_classes = "border-rose-400 focus:border-rose-500 focus:ring-rose-500/30"
  label_classes = "block text-sm font-medium text-slate-700"
  hint_classes = "mt-1 block text-xs text-slate-500"
  # rose-600 is 4.51:1 on white -- it passes, but only just, so error text uses -700.
  error_classes = "mt-1 block text-xs font-medium text-rose-700"

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

  # A single checkbox: control and label sit on one line, label to the right.
  config.wrappers :essentials_boolean, tag: "div", class: "mb-4" do |b|
    b.use :html5
    b.optional :readonly
    b.wrapper tag: "div", class: "flex items-start gap-2" do |ba|
      ba.use :input, class: "mt-0.5 h-4 w-4 rounded border-slate-300 text-brand-600 focus:ring-2 focus:ring-brand-500/30"
      ba.use :label, class: "text-sm text-slate-700"
    end
    b.use :full_error, wrap_with: {tag: "p", class: error_classes}
    b.use :hint, wrap_with: {tag: "p", class: hint_classes}
  end

  # Radio and checkbox collections get a real <fieldset>/<legend> so the group is named.
  config.wrappers :essentials_collection,
    tag: "fieldset",
    class: "mb-4",
    item_wrapper_class: "flex items-center gap-2",
    item_label_class: "text-sm text-slate-700" do |b|
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
    file: :essentials_file
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
