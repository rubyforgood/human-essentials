# Component helpers for the Ruby for Good design system (see design.md).
#
# These are the Tailwind counterparts of UiHelper. UiHelper stays untouched and keeps
# serving the un-migrated Bootstrap pages; nothing here is used on a Bootstrap page and
# nothing there is used on a Tailwind page. When the last Bootstrap page is migrated,
# UiHelper is deleted and these lose the `essentials_` prefix.
module EssentialsUiHelper
  # --- Buttons --------------------------------------------------------------
  #
  # One treatment per role. The variant carries the meaning, the size carries the
  # context (`sm` for a row action, `md` for a page or section action).

  BUTTON_BASE = "inline-flex items-center justify-center gap-1.5 rounded-lg font-medium " \
                "transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 " \
                "disabled:cursor-not-allowed disabled:opacity-60"

  BUTTON_VARIANTS = {
    primary: "bg-brand-600 text-white hover:bg-brand-700 focus-visible:outline-brand-600",
    secondary: "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50 focus-visible:outline-brand-600",
    danger: "bg-rose-600 text-white hover:bg-rose-700 focus-visible:outline-rose-600",
    ghost: "text-slate-600 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-brand-600"
  }.freeze

  BUTTON_SIZES = {
    sm: "px-2.5 py-1.5 text-xs",
    md: "px-3.5 py-2 text-sm"
  }.freeze

  def essentials_button_classes(variant: :primary, size: :md, extra: nil)
    [
      BUTTON_BASE,
      BUTTON_VARIANTS.fetch(variant.to_sym),
      BUTTON_SIZES.fetch(size.to_sym),
      extra
    ].compact.join(" ")
  end

  # A link styled as a button. Use for navigation (GET).
  def essentials_link_button(label, path, variant: :primary, size: :md, icon: nil, **html_attrs)
    classes = essentials_button_classes(variant: variant, size: size, extra: html_attrs.delete(:class))
    link_to path, class: classes, **html_attrs do
      safe_join([(tag.i(nil, class: icon, aria: {hidden: true}) if icon), label].compact, " ")
    end
  end

  # A real button that submits or mutates. `method:` routes it through button_to so the
  # verb, CSRF token and disable_with guard are all handled.
  def essentials_action_button(label, path, method:, variant: :primary, size: :md, icon: nil, confirm: nil, **html_attrs)
    classes = essentials_button_classes(variant: variant, size: size, extra: html_attrs.delete(:class))
    data = {disable_with: "Please wait..."}.merge(html_attrs.delete(:data) || {})
    # data-confirm, not data-turbo-confirm: rails-ujs is what this app loads, and Turbo would
    # only act on its own attribute where Turbo Drive is enabled -- which is per-action here.
    data[:confirm] = confirm if confirm

    button_to path, method: method, class: classes, form_class: "inline-block",
      data: data, **html_attrs do
      safe_join([(tag.i(nil, class: icon, aria: {hidden: true}) if icon), label].compact, " ")
    end
  end

  # --- Status pills ---------------------------------------------------------
  #
  # Never colour alone: every tone pairs its colour with a word, and callers may add an
  # icon. Text tones are the -700 step because -600 fails 4.5:1 for small text.

  PILL_TONES = {
    neutral: "bg-slate-100 text-slate-700",
    info: "bg-sky-50 text-sky-700",
    success: "bg-emerald-50 text-emerald-700",
    warning: "bg-amber-50 text-amber-700",
    danger: "bg-rose-50 text-rose-700",
    brand: "bg-brand-50 text-brand-700"
  }.freeze

  def essentials_status_pill(label, tone: :neutral, icon: nil)
    tag.span(class: "inline-flex items-center gap-1 whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium #{PILL_TONES.fetch(tone.to_sym)}") do
      safe_join([(tag.i(nil, class: icon, aria: {hidden: true}) if icon), label].compact, " ")
    end
  end

  # --- Stats ----------------------------------------------------------------
  #
  # A figure and the words that say what it counts. A description list, because that is the
  # relationship: the label describes the value.
  #
  # The reports previously marked these up as <h2>, which put a page's statistics into its
  # heading outline -- someone navigating by heading heard "Total spent on diapers: $412" as
  # document structure. They also set the figure in a <p> at text-2xl while the real headings
  # were text-base, so the visual hierarchy ran opposite to the semantic one.
  #
  # `value_class` exists for the spec hooks the request specs match on (`total_distributed`
  # and friends); it is not for styling.
  #
  # `title:` and `subtitle:` give the band a header. Without one the card is a row of numbers
  # with nothing saying what they are or what they cover -- and a bare period above it read as
  # though it might belong to the table underneath rather than to the figures.
  #
  # The subtitle's job is *scope*: how many, whether the filters are narrowing it, and over what
  # period. `essentials_stats_scope` builds that sentence. Sentence case throughout, and
  # deliberately not the uppercase-with-tracking eyebrow this slot usually attracts -- design.md
  # is unambiguous that everything a person reads is sentence case.
  def essentials_stats(stats, title: nil, subtitle: nil)
    grid = essentials_stats_grid(stats)

    tag.div(class: "overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm") do
      if title.present?
        concat(tag.div(class: "border-b border-slate-200 px-5 py-3") do
          concat tag.h2(title, class: "text-base font-semibold text-slate-900")
          # data-filter-scope: the auto-submit controller copies this into its live region
          # after a frame swap, because it already says what is now on screen.
          if subtitle.present?
            concat tag.p(subtitle, class: "mt-0.5 text-sm text-slate-600", data: {filter_scope: true})
          end
        end)
      end
      concat grid
    end
  end

  # "13 donations matching these filters, over the last 30 days."
  #
  # The count and the noun come from the caller, because only the page knows them. Whether to say
  # "matching these filters" is decided here, and it ignores the date range on purpose: a date
  # range is always set, so counting it would make every page claim to be filtered when the user
  # has touched nothing.
  #
  # No leading "The", because it does not survive the edges: "The 1 donation" and "The 0
  # donations" both read as though a machine wrote them. Zero gets "No" for the same reason.
  def essentials_stats_scope(count, noun)
    counted = count.zero? ? "No #{noun.pluralize}" : "#{number_with_delimiter(count)} #{noun.pluralize(count)}"
    qualifier = essentials_filtered_beyond_dates? ? " matching these filters" : ""

    "#{counted}#{qualifier}, #{date_range_label}"
  end

  # Is anything other than the date range being filtered on?
  DATE_FILTER_KEYS = %w[date_range date_range_label].freeze

  def essentials_filtered_beyond_dates?
    return true if params[:filterrific].present?

    filters = params[:filters]
    return false if filters.blank?

    filters.to_unsafe_h.except(*DATE_FILTER_KEYS).any? { |_key, value| value.present? }
  end

  # How many columns, for a given number of figures.
  #
  # The count has to divide the column count exactly. This was a flat
  # `sm:grid-cols-2 lg:grid-cols-3` whatever the number of figures, which orphaned a tile on
  # every page that had a band -- four figures went 3 + 1 at desktop, three went 2 + 1 at
  # tablet. An empty cell is worse here than it was before, too: with the separators drawn by
  # the backdrop showing through the gaps, a missing cell shows as a grey block.
  #
  # Five is stacked until `lg` on purpose: five columns at 640px leaves about 128px each, which
  # a figure like "$11,312.00" at text-2xl does not fit into.
  STATS_COLUMNS = {
    1 => "",
    2 => "sm:grid-cols-2",
    3 => "sm:grid-cols-3",
    4 => "sm:grid-cols-2 lg:grid-cols-4",
    5 => "lg:grid-cols-5",
    6 => "sm:grid-cols-2 lg:grid-cols-3"
  }.freeze

  # One card, with the figures separated by hairlines rather than each sitting in its own filled
  # box. Four fills read as four objects; the point of a summary band is that it is one reading.
  # This is the metric strip Stripe, Shopify and Linear all use.
  #
  # The separators are the `gap-px` grid showing a slate-200 backdrop through the gaps between
  # white cells, which draws a hairline between every pair of neighbours -- rows as well as
  # columns. `divide-x` cannot: in a grid of more than one row it borders by DOM order rather
  # than by position, so a 2x2 arrangement comes out wrong.
  def essentials_stats_grid(stats)
    columns = STATS_COLUMNS.fetch(stats.size, "sm:grid-cols-2 lg:grid-cols-4")

    tag.dl(class: "grid gap-px bg-slate-200 #{columns}") do
      safe_join(stats.map { |stat|
        tag.div(class: "bg-white px-5 py-4") do
          concat tag.dt(stat[:label], class: "text-sm font-medium text-slate-600")
          # to_s matters: a block given to `tag` renders nothing for a non-String, so an
          # Integer value came out as an empty figure. Caught by reading the rendered page
          # rather than the template -- "Total items" was blank while every currency stat,
          # already a String, was fine.
          value = stat[:value].to_s
          concat tag.dd(class: "mt-1 text-2xl font-bold tracking-tight text-slate-900") {
            if stat[:value_class] || stat[:value_id]
              tag.span(value, class: stat[:value_class], id: stat[:value_id])
            else
              value
            end
          }
        end
      })
    end
  end

  # --- Icon tile ------------------------------------------------------------
  #
  # A soft coloured tile behind an icon means "a stat or a status". A person is an
  # initials avatar instead. Keeping these disjoint is what makes either one readable.
  def essentials_icon_tile(icon, tone: :brand)
    tone_classes = {
      brand: "bg-brand-50 text-brand-600",
      info: "bg-sky-50 text-sky-600",
      success: "bg-emerald-50 text-emerald-600",
      warning: "bg-amber-50 text-amber-600",
      danger: "bg-rose-50 text-rose-600",
      neutral: "bg-slate-100 text-slate-600"
    }.fetch(tone.to_sym)

    tag.span(tag.i(nil, class: icon, aria: {hidden: true}),
      class: "grid h-9 w-9 shrink-0 place-items-center rounded-xl #{tone_classes}")
  end

  # --- Identity -------------------------------------------------------------

  # Up to two initials. Presentation only -- never mutate the stored name.
  def essentials_avatar_initials(name)
    return "?" if name.blank?

    name.to_s.split(/\s+/).compact_blank.first(2).map { |part| part[0] }.join.upcase
  end

  def essentials_role_label(role)
    case role.name
    when Role::ORG_ADMIN.to_s then "Organization admin"
    when Role::ORG_USER.to_s then "Organization user"
    when Role::SUPER_ADMIN.to_s then "Super admin"
    when Role::PARTNER.to_s then "Partner"
    else role.name.to_s.humanize
    end
  end

  # --- Flash ----------------------------------------------------------------
  #
  # Mirrors ApplicationHelper#flash_class, which maps the same four keys for the
  # Bootstrap shell. Both must stay in step until the Bootstrap shell is gone.
  def essentials_flash_tone(key)
    case key.to_s
    when "success" then :success
    when "error" then :danger
    when "alert" then :warning
    else :info
    end
  end

  FLASH_STYLES = {
    info: {bar: "border-sky-200 bg-sky-50 text-sky-900", icon: "bi-info-circle text-sky-600"},
    success: {bar: "border-emerald-200 bg-emerald-50 text-emerald-900", icon: "bi-check-circle text-emerald-600"},
    warning: {bar: "border-amber-200 bg-amber-50 text-amber-900", icon: "bi-exclamation-triangle text-amber-600"},
    danger: {bar: "border-rose-200 bg-rose-50 text-rose-900", icon: "bi-x-circle text-rose-600"}
  }.freeze

  def essentials_flash_style(tone)
    FLASH_STYLES.fetch(tone.to_sym)
  end

  # --- Forms ----------------------------------------------------------------

  # Which wrapper each input type gets. Lives here rather than on SimpleForm itself: the
  # wrappers are defined in config/initializers/simple_form_essentials.rb, but adding a
  # method to a gem's module to hold app config is a monkeypatch nobody would think to
  # look for.
  WRAPPER_MAPPINGS = {
    boolean: :essentials_boolean,
    check_boxes: :essentials_collection,
    radio_buttons: :essentials_collection,
    file: :essentials_file
  }.freeze

  # simple_form_for with the design system's wrappers already applied. Use this rather than
  # passing `wrapper:` at every call site -- forgetting it silently renders a Bootstrap form
  # on a page with no Bootstrap CSS, which looks like an unstyled browser default.
  def essentials_form_for(record, options = {}, &block)
    simple_form_for(
      record,
      options.deep_merge(wrapper: :essentials, wrapper_mappings: WRAPPER_MAPPINGS),
      &block
    )
  end

  # The error summary that sits above a form. Named the field, has role="alert", and links
  # each message to its input so a keyboard user can jump straight to the problem.
  def essentials_error_summary(record)
    return if record.blank? || record.errors.empty?

    tag.div(class: "mb-5 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3", role: "alert") do
      concat tag.p("#{pluralize(record.errors.count, "error")} prevented this from being saved:",
        class: "flex items-center gap-2 text-sm font-semibold text-rose-900")
      concat(tag.ul(class: "mt-2 list-inside list-disc space-y-1 text-sm text-rose-800") do
        safe_join(record.errors.map { |error| tag.li(error.full_message) })
      end)
    end
  end

  # Is the current page filtered? Decides between the "nothing here yet" and "nothing
  # matches" empty states.
  #
  # Reads params directly rather than the controller's `filter_params`: only some controllers
  # define that (it is a private method on about half of them, not a shared concern), so a
  # view calling it is one un-filtered controller away from a NameError -- which is exactly
  # how the audits index 500'd.
  def essentials_filtered?
    params[:filters].present? || params[:filterrific].present?
  end

  # --- Filter controls ------------------------------------------------------
  #
  # FilterHelper builds the selects, text fields and checkboxes; these constants are the
  # single definition of what one looks like, shared by both helpers. Only the options-array
  # variant lives here, because FilterHelper has no equivalent for it.

  FILTER_CONTROL_BASE = "mt-1.5 block w-full rounded-lg border border-slate-300 bg-white " \
                        "py-2 text-sm text-slate-900 shadow-sm focus:border-brand-500 " \
                        "focus:ring-2 focus:ring-brand-500/30 focus:outline-none"

  # Text inputs and date pickers: even padding.
  FILTER_CONTROL_CLASSES = "#{FILTER_CONTROL_BASE} px-3"

  # Selects: `pr-10` reserves room so the longest option ("Recertification required (1)") does
  # not run under the chevron, and `.filter-select` replaces the native arrow with one we can
  # position -- the native one sits 4px from the border whatever the padding says.
  FILTER_SELECT_CLASSES = "#{FILTER_CONTROL_BASE} filter-select pl-3 pr-10"

  FILTER_LABEL_CLASSES = "block text-sm font-medium text-slate-700"

  # A floating panel anchored to a trigger: the account menu, the date range picker.
  #
  # Same surface as a dialog, because it is the same idea -- something above the page rather than
  # part of it. The elevation scale has two steps on purpose: `shadow-sm` for things in the page,
  # `shadow-xl` for things over it. The account menus used `shadow-lg`, which was a third step
  # nothing else shared.
  POPOVER_SURFACE_CLASSES = "rounded-2xl border border-slate-200 bg-white shadow-xl"

  # The trigger reads as a control, not a button: it sits in a filter grid beside real selects and
  # has to line up with them.
  POPOVER_TRIGGER_CLASSES = "#{FILTER_CONTROL_BASE} flex items-center justify-between gap-2 px-3 text-left"

  # Meta text, per design.md: slate-500 at text-xs. 4.8:1 on white, which clears AA for body
  # text. Matches the hint style simple_form already uses on every form in the app.
  FILTER_HINT_CLASSES = "mt-1 block text-xs text-slate-500"

  # For a filter whose options are a plain array rather than a collection of records.
  def essentials_filter_options(scope:, options:, label: nil, selected: nil)
    label ||= "Filter #{scope.to_s.tr("_", " ")}"
    id = "filters_#{scope}_#{SecureRandom.uuid}"

    label_tag(id, label, class: FILTER_LABEL_CLASSES) +
      select_tag("filters[#{scope}]", options_for_select(options, selected),
        include_blank: true, class: FILTER_SELECT_CLASSES, id: id)
  end

  # --- Top bar help link ----------------------------------------------------

  def help_link_path
    if current_user&.has_cached_role?(Role::ORG_ADMIN, current_organization) ||
        current_user&.has_cached_role?(Role::ORG_USER, current_organization)
      "https://rubyforgood.github.io/human-essentials/user_guide/bank/"
    else
      help_path
    end
  end

  def help_link_label
    (help_link_path == help_path) ? "Need help?" : "User guide"
  end

  # Not a question mark. A circled "?" is the shape this app uses for "something needs your
  # attention", so beside a label it reads as a warning rather than an offer of help. A guide
  # is a book; in-app help is a life ring.
  def help_link_icon
    (help_link_path == help_path) ? "bi-life-preserver" : "bi-book"
  end

  # The pager for a table card, ready for the card's `footer:` slot:
  #
  #   render "shared/essentials/card", padded: false,
  #          footer: essentials_pagination_footer(@paginated_things) do
  #
  # It returns nil -- not an empty string -- for a collection that fits on one page, so the
  # card skips the footer instead of drawing an empty bordered strip. Call sites used to do
  # `capture { concat(render(...)) }` and let the card test the result for blankness, which
  # worked in production and failed in development: annotate_rendered_view_with_filenames
  # puts an HTML comment in the buffer, so the "blank" capture was never blank.
  def essentials_pagination_footer(collection, page_params: {})
    return nil unless collection.respond_to?(:total_pages) && collection.total_pages > 1

    render "shared/essentials/pagination", collection: collection, page_params: page_params
  end
end
