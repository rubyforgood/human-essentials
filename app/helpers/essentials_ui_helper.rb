# Component helpers for the Ruby for Good design system (see design.md).
#
# These are the Tailwind counterparts of UiHelper. UiHelper stays untouched and keeps
# serving the un-migrated Bootstrap pages; nothing here is used on a Bootstrap page and
# nothing there is used on a Tailwind page. When the last Bootstrap page is migrated,
# UiHelper is deleted and these lose the `essentials_` prefix.
module EssentialsUiHelper
  # Flash entries that are signals rather than sentences, and so are not drawn by the flash strip.
  # `handle_csv_export` sets `trigger_csv_download` to carry a boolean across its redirect; the
  # strip renders every key it finds, so without this the page grew a message bar reading "true".
  NON_MESSAGE_FLASH_KEYS = %w[trigger_csv_download].freeze

  # --- Buttons --------------------------------------------------------------
  #
  # One treatment per role. The variant carries the meaning, the size carries the
  # context (`sm` for a row action, `md` for a page or section action).

  BUTTON_BASE = "inline-flex items-center justify-center gap-1.5 rounded-lg font-medium " \
                "transition-colors focus-visible:outline-2 focus-visible:outline-offset-2 " \
                "disabled:cursor-not-allowed disabled:opacity-60"

  # Every variant carries a border, transparent where it is not meant to be seen. design.md fixes
  # the control height at 38px, and `border` is 1px top and bottom: without this a `:primary` is
  # 36px and a `:secondary` beside it is 38, which is exactly what /requests showed once its four
  # buttons became two. Measured across 17 pages before the fix: 25 secondary at 38px, 16 primary
  # and 4 ghost at 36px.
  BUTTON_VARIANTS = {
    primary: "border border-transparent bg-brand-600 text-white hover:bg-brand-700 focus-visible:outline-brand-600",
    secondary: "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50 focus-visible:outline-brand-600",
    danger: "border border-transparent bg-rose-600 text-white hover:bg-rose-700 focus-visible:outline-rose-600",
    ghost: "border border-transparent text-slate-600 hover:bg-slate-100 hover:text-slate-900 focus-visible:outline-brand-600",
    # A destructive action with no fill. Not `ghost` plus `extra: "text-rose-700"` -- that puts two
    # colour utilities in one class attribute, and the cascade picks the winner rather than the
    # attribute order, so the rose lost to the ghost's own slate everywhere it was tried.
    # `remove_element_button` did exactly that, and one caller had already worked around it by
    # passing a whole replacement class string.
    #
    # `slate-600` at rest, like `ghost`, and rose only on hover and focus. It was rose-700 at rest,
    # which contradicted the rule design.md already carried for the same control in a repeating
    # row: an eight-row form should not carry eight red marks down its edge. The word "Remove" and
    # the trash glyph say it is destructive; the colour does not have to say it a third time, and
    # saying it on every row makes the one you are pointing at no louder than the rest. Same
    # argument that took the inline error message grey.
    ghost_danger: "border border-transparent text-slate-600 hover:bg-rose-50 hover:text-rose-700 focus-visible:outline-rose-600"
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

  # An action in a table row, icon-only at `size-7`.
  #
  # 28px, which is the kebab trigger's height, so a column mixing the two does not step by 2px --
  # that was visible on /vendors and /requests. Uniform icon buttons in this column is what Carbon
  # and Salesforce ship.
  #
  # **Icon-only is what makes a frozen actions column affordable.** The column is pinned to the
  # right edge so it can be reached without scrolling, which means it occupies its width
  # permanently. Measured at 1024: a labelled pair ran 168-273px and the same pair as icons is a
  # uniform **94px** -- narrower than three of the five kebab columns, and unlike collapsing into a
  # menu it costs no extra click.
  #
  # **`data-tooltip`, never `title`.** A `title` is browser chrome: unstyleable, silent on keyboard
  # focus, and failing WCAG 1.4.13 three ways. `tooltip_controller` shows the same string on hover
  # *and* focus, dismissible with Escape and hoverable. `aria-label` remains the accessible name and
  # the bubble is `aria-hidden`, so the action is announced once rather than twice.
  ROW_ICON_CLASSES = "inline-flex size-7 items-center justify-center rounded-lg transition-colors " \
                     "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600"
  ROW_ICON_TONES = {
    ghost: "text-slate-500 hover:bg-slate-100 hover:text-slate-900",
    danger: "text-slate-600 hover:bg-rose-50 hover:text-rose-700"
  }.freeze

  def essentials_row_icon_classes(tone: :ghost)
    "#{ROW_ICON_CLASSES} #{ROW_ICON_TONES.fetch(tone.to_sym)}"
  end

  def essentials_row_icon_link(label, path, icon:, tone: :ghost, **html_attrs)
    link_to path, "aria-label": label, data: {tooltip: label}.merge(html_attrs.delete(:data) || {}),
      class: essentials_row_icon_classes(tone: tone), **html_attrs do
      tag.i(nil, class: icon, aria: {hidden: true})
    end
  end

  # The same control for an action that is not a GET.
  def essentials_row_icon_action(label, path, method:, icon:, tone: :ghost, confirm: nil)
    essentials_action_button(label, path, method: method, icon: icon, confirm: confirm,
      icon_only: true, variant: ((tone.to_sym == :danger) ? :ghost_danger : :ghost))
  end

  # A record's own actions in a page header -- its Edit, its Delete.
  #
  # They belong in the header rather than at the foot of the page, because they act on the record as
  # a whole; design.md names *Deactivate* as the example. They belong in an **overflow** rather than
  # beside the primary, because the header allows three actions and a menu counts as one, and
  # because the last slot is the primary's -- a destructive action must never inherit it by being
  # last in the list. That is what `/product_drives` did, and it was reported as the buttons looking
  # reversed.
  #
  # **One item is not a menu.** With a single action -- a distribution has an Edit and no Delete,
  # and a non-admin sees Edit alone everywhere -- a kebab hides one thing behind a click and a
  # generic name. It renders as an ordinary secondary button instead, which still leaves the last
  # slot free if the caller puts it before the primary. `menu_button` makes the same call for the
  # same reason.
  def essentials_record_actions(label:, items:)
    items = items.compact
    return if items.empty?

    if items.one?
      only = items.first
      return essentials_link_button(only[:label], only[:path], variant: :secondary, icon: only[:icon]) unless only[:method]

      return essentials_action_button(only[:label], only[:path], method: only[:method],
        variant: (only[:tone] == :danger) ? :ghost_danger : :secondary,
        icon: only[:icon], confirm: only[:confirm])
    end

    render("shared/essentials/row_actions", label: label, size: :md, items: items)
  end

  # One segment of a segmented toggle -- the calendar's range and layout switchers. Its state is
  # `aria-pressed`, and the styling hangs off the attribute so markup and appearance cannot
  # disagree. `first:` drops the divider, which belongs between segments rather than before them.
  def essentials_view_toggle_classes(first: false)
    [
      "px-3 py-1.5 text-xs font-medium text-slate-700 transition-colors",
      "hover:bg-slate-50 aria-pressed:bg-slate-100 aria-pressed:text-slate-900",
      "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600",
      ("border-l border-slate-300" unless first)
    ].compact.join(" ")
  end

  # Two short fields side by side inside a form.
  #
  #   <%= essentials_field_row do %>
  #     <%= f.input :value_in_dollars, label: "Value per item" %>
  #     <%= f.input :distribution_quantity, label: "Quantity per individual" %>
  #   <% end %>
  #
  # Only for fields short enough that a full-width input would be absurd -- a price, a quantity, a
  # date -- and only where the two belong together. The DOM order is the order they are read and
  # filled, so a pair that is not really a pair costs a screen reader user more than it saves anyone.
  #
  # It stacks below `sm`, so the row is a row only where there is width for one. The default
  # `:essentials` wrapper already carries `mb-4`, which is the vertical rhythm; this adds the
  # horizontal gap and nothing else.
  def essentials_field_row(&block)
    tag.div(capture(&block), class: "grid gap-x-4 sm:grid-cols-2")
  end

  # One field in a record's detail list: a `<dt>`/`<dd>` pair wrapped in a `<div>`, which is how
  # HTML5 groups them inside a `<dl>`.
  #
  #   <dl class="grid gap-x-6 gap-y-4 sm:grid-cols-2">
  #     <%= essentials_detail("Name", @organization.name) %>
  #     <%= essentials_detail("URL", wide: true) { link_to ... } %>
  #   </dl>
  #
  # A blank value renders the em dash, which is the convention in sixteen other places and is why
  # this takes the value rather than leaving each caller to write `presence ||`. "Not defined" reads
  # as a sentence and makes an empty field look like it says something.
  #
  # `wide:` spans both columns, for a value that is a paragraph, a list or an image rather than a
  # word -- those look wrong in a half-width column and push their neighbour out of line.
  def essentials_detail(label, value = nil, wide: false, &block)
    body = block ? capture(&block) : value
    body = "—" if body.blank?

    tag.div(class: ("sm:col-span-2" if wide)) do
      tag.dt(label, class: "text-xs font-medium text-slate-500") +
        tag.dd(body, class: "mt-0.5 text-sm text-slate-900")
    end
  end

  # The subtitle on a "recently added" dashboard card: what period it covers, and whether the list
  # under it is the whole of that period or only the top of it.
  #
  # This replaces a status pill in the card header's `actions:` slot, which was wrong three ways: a
  # count is not a status, a status is not an action, and the number was the *shown* count rather
  # than the total -- `@recent_users` is `.limit(20)`, and `.limit(20).count` returns 20, so the
  # card read "20 new users" when 23 had signed up. A page size presented as a total is the exact
  # thing essentials_pagination_summary was written to stop, and its "Showing 20 of 23" is the
  # phrasing borrowed here.
  #
  # The period was worth saying whatever the count did: before this it appeared only in the card's
  # *empty* state ("No new users this week"), so a reader who saw a list was never told what
  # "recently" meant.
  #
  # `total:` is only needed where the list is capped. Left out, it is the shown count, which is the
  # truth for an uncapped list -- and the moment someone adds a `.limit` they have to pass it, which
  # is the point: the caller is made to say whether the number it is showing is the whole of it.
  def essentials_recent_subtitle(shown, total: nil, noun: nil)
    total ||= shown
    return "Added in the last week." if total <= shown

    "The #{number_with_delimiter(shown)} most recent of #{number_with_delimiter(total)} " \
      "#{noun} added in the last week."
  end

  # A form's action row: Save and Cancel, *below* the card rather than inside it.
  #
  # The buttons belong to the form, not to a card. A card groups related content; the submit
  # commits the whole form, which on seven of these forms spans two or three cards and belongs to
  # none of them. That was already how every multi-card form worked -- donations, purchases,
  # distributions, transfers, audits, adjustments, kits -- while 33 single-card forms drew the row
  # inside the card under a divider. The divider was the visible symptom: drawn inside the card's
  # 20px body padding, it measured 854px of rule in an 896px card, the only rule in the app that
  # did not reach the edges of what it divided.
  #
  # No divider here at all. Off the surface, the card's own edge is the boundary, and a second line
  # under it would be the two-mechanisms-for-one-job pattern again.
  #
  # `mt-6` is the gap to the card above -- 24px, matching the `space-y-6` that multi-card forms
  # already put between their cards, so the buttons sit off the stack at the stack's own rhythm.
  #
  # The row is left-aligned, which is why its primary comes *first*: see design.md. A page header's
  # actions are right-aligned and so put the primary last. One rule -- the primary sits at the row's
  # alignment edge -- and it reads as two only if you forget which edge each row has.
  def essentials_form_actions(&block)
    tag.div(capture(&block), class: "mt-6 flex flex-wrap items-center gap-2")
  end

  # A link styled as a button. Use for navigation (GET).
  #
  # `available: false` renders a non-interactive `<span>` rather than an `<a>`, because **a link
  # cannot be disabled** -- it stays focusable and clickable by keyboard and announces nothing.
  # This is the treatment pagination's ends already get, and the styling hangs off the attribute so
  # markup and appearance cannot disagree. `reason:` is sr-only text saying why, which design.md
  # asks of every unavailable action -- "greyed out" on its own leaves the reader guessing.
  def essentials_link_button(label, path, variant: :primary, size: :md, icon: nil,
    available: true, reason: nil, **html_attrs)
    classes = essentials_button_classes(variant: variant, size: size, extra: html_attrs.delete(:class))
    body = safe_join([(tag.i(nil, class: icon, aria: {hidden: true}) if icon), label].compact, " ")

    unless available
      content = safe_join([body, (tag.span(reason, class: "sr-only") if reason)].compact)
      return tag.span(content, class: "#{classes} cursor-not-allowed opacity-60",
        aria: {disabled: true}, **html_attrs)
    end

    link_to path, class: classes, **html_attrs do
      body
    end
  end

  # A real button that submits or mutates. `method:` routes it through button_to so the
  # verb, CSRF token and disable_with guard are all handled.
  # `icon_only: true` renders the same control as `essentials_row_icon_link` -- 28px, the label as
  # `aria-label` and `data-tooltip` rather than as text. It is an option here rather than a second
  # helper because everything below this line (the `turbo: false`, the confirm wiring, the derived
  # confirm label and tone) was hard enough to get right once.
  def essentials_action_button(label, path, method:, variant: :primary, size: :md, icon: nil,
    confirm: nil, icon_only: false, **html_attrs)
    classes = if icon_only
      essentials_row_icon_classes(tone: (%i[danger ghost_danger].include?(variant.to_sym) ? :danger : :ghost))
    else
      essentials_button_classes(variant: variant, size: size, extra: html_attrs.delete(:class))
    end
    # `turbo: false`, so the browser submits the form itself.
    #
    # These buttons sit in table rows, and the tables sit inside a results turbo-frame. Turbo's
    # `elementIsNavigatable` returns true for anything inside a frame *even when Drive is off*,
    # so Turbo intercepted the submission, fetched the redirect, and then had to promote it to a
    # top-level visit because the frame carries `target="_top"`. That last step is where it came
    # apart: the confirm was accepted, the submit event fired, the server handled the PUT -- and
    # about half the time the page never changed. Reactivate stayed on screen with the previous
    # flash still above it.
    #
    # A row action is a whole-page navigation that ends in a redirect and a flash, not a frame
    # update, so opting out is what it wanted all along. Measured on
    # storage_location_system_spec:167, which had been failing 4 runs in 8: 0 in 20 after.
    data = {disable_with: "Please wait...", turbo: false}.merge(html_attrs.delete(:data) || {})
    # data-confirm, not data-turbo-confirm: rails-ujs is what this app loads, and Turbo would
    # only act on its own attribute where Turbo Drive is enabled -- which is per-action here.
    if confirm
      data[:confirm] = confirm
      # The dialog's confirm button says what it will do -- "Deactivate", not "Continue" -- and
      # turns red for a destructive variant. Derived here so a call site cannot set a red button
      # on a harmless action or a grey one on a delete.
      data[:confirm_label] ||= label
      data[:confirm_tone] ||= "danger" if %i[danger ghost_danger].include?(variant.to_sym)
    end

    if icon_only
      html_attrs["aria-label"] ||= label
      data[:tooltip] ||= label
    end

    button_to path, method: method, class: classes, form_class: "inline-block",
      data: data, **html_attrs do
      if icon_only
        tag.i(nil, class: icon, aria: {hidden: true})
      else
        safe_join([(tag.i(nil, class: icon, aria: {hidden: true}) if icon), label].compact, " ")
      end
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

    tag.div(class: "card-surface overflow-hidden") do
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

  # Tailwind generates a utility only if it finds the literal string in a source file, so a class
  # built from a runtime value -- `lg:grid-cols-<%= metrics.size %>` -- exists only by luck,
  # when some unrelated view happens to use the same number. Two grids were relying on that:
  # `lg:grid-cols-1`, `-6`, `-7` and `-8` are not in the stylesheet at all today, so a fourth
  # metric appearing on the partner header would have silently unstyled it. Go through the map.
  def essentials_grid_columns(count)
    STATS_COLUMNS.fetch(count, "sm:grid-cols-2 lg:grid-cols-4")
  end

  # One card, with the figures separated by hairlines rather than each sitting in its own filled
  # box. Four fills read as four objects; the point of a summary band is that it is one reading.
  # This is the metric strip Stripe, Shopify and Linear all use.
  #
  # The separators are the `gap-px` grid showing a slate-200 backdrop through the gaps between
  # white cells, which draws a hairline between every pair of neighbours -- rows as well as
  # columns. `divide-x` cannot: in a grid of more than one row it borders by DOM order rather
  # than by position, so a 2x2 arrangement comes out wrong.
  def essentials_stats_grid(stats)
    columns = essentials_grid_columns(stats.size)

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
  # Bands on a stacked chart. Four in practice -- the item categories a bank maintains -- and
  # capped by the palette rather than by the data: past about eight, a legend stops being a key,
  # which is the fault the 47-series chart was rebuilt to escape. Ordered so adjacent bands differ
  # in lightness as well as hue, for anyone reading it without colour.
  CHART_BAND_COLOURS = ["#4F46E5", "#0EA5E9", "#14B8A6", "#F59E0B", "#EC4899", "#8B5CF6",
    "#0891B2", "#65A30D"].freeze

  # --- Sparkline ------------------------------------------------------------
  #
  # A twelve-point trend, drawn inline, for one row of a table.
  #
  #   <td class="trend"><%= essentials_sparkline(item[:data], months: last_12_months) %></td>
  #
  # Server-rendered SVG rather than a charting library: it is 47 of these on one page, none of them
  # interactive, and a library would cost a second Highcharts instance per row. It also means the
  # cell has its final size in the first paint, so nothing moves.
  #
  # **Accessibility.** The drawing is `aria-hidden` and the cell carries an `sr-only` sentence
  # naming the peak month and value. That is not a restatement of the row -- the twelve numbers are
  # already in it -- it is the one thing the *shape* says that reading twelve numbers in order does
  # not give you for free. design.md: a chart is never the only representation of its data.
  SPARK_W = 44
  SPARK_H = 26

  def essentials_sparkline(values, months: [])
    values = Array(values).map(&:to_i)
    return tag.span("—", class: "text-slate-400") if values.empty? || values.sum.zero?

    top = values.max
    step = (values.size > 1) ? SPARK_W.to_f / (values.size - 1) : 0
    points = values.each_with_index.map { |v, i|
      # 2px of padding top and bottom so a peak or a zero is not clipped by the viewBox.
      "#{(i * step).round(1)},#{(SPARK_H - 2 - (SPARK_H - 4) * v / top.to_f).round(1)}"
    }.join(" ")
    last_x, last_y = points.split(" ").last.split(",")

    peak_index = values.index(top)
    peak_month = months[peak_index]
    description = peak_month ? "Peaks at #{number_with_delimiter(top)} in #{peak_month}." : "Peaks at #{number_with_delimiter(top)}."

    safe_join([
      tag.svg(
        safe_join([
          tag.polyline(nil, points: points, fill: "none", stroke: "currentColor",
            "stroke-width": "1.5", "stroke-linejoin": "round", "stroke-linecap": "round"),
          tag.circle(nil, cx: last_x, cy: last_y, r: "2.2", fill: "currentColor")
        ]),
        viewBox: "0 0 #{SPARK_W + 4} #{SPARK_H}", width: SPARK_W + 4, height: SPARK_H,
        class: "inline-block align-middle text-brand-600",
        aria: {hidden: true}, focusable: "false"
      ),
      tag.span(description, class: "sr-only")
    ])
  end

  # A soft coloured tile behind an icon means "a stat or a status". A person is an
  # initials avatar instead. Keeping these disjoint is what makes either one readable.
  # Two sizes, named as the buttons are: `md` is the default and stands beside a figure or a
  # `text-base` heading; `sm` is for a compact card header, where a 36px tile next to a `text-sm`
  # heading reads as heavy. The reports hub had built its own `sm` inline -- 28px, `rounded-lg`
  # and `text-brand-700` against this helper's `text-brand-600`, so three things had drifted
  # rather than one.
  ICON_TILE_SIZES = {
    sm: "size-7 rounded-lg",
    md: "size-9 rounded-xl"
  }.freeze

  ICON_TILE_TONES = {
    brand: "bg-brand-50 text-brand-600",
    info: "bg-sky-50 text-sky-600",
    success: "bg-emerald-50 text-emerald-600",
    warning: "bg-amber-50 text-amber-600",
    danger: "bg-rose-50 text-rose-600",
    neutral: "bg-slate-100 text-slate-600"
  }.freeze

  def essentials_icon_tile(icon, tone: :brand, size: :md)
    tag.span(tag.i(nil, class: icon, aria: {hidden: true}),
      class: "grid shrink-0 place-items-center " \
             "#{ICON_TILE_SIZES.fetch(size.to_sym)} #{ICON_TILE_TONES.fetch(tone.to_sym)}")
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
  # No required legend. The marker is a red asterisk, which is the convention, and a line of
  # explanatory text above every form was costing ~32px of the card's first screen to restate it.
  # The programmatic signals are unchanged: `abbr@title` on the marker, `aria-required` on the
  # input. See docs/design-decisions.md -- this reverses an earlier call.
  def essentials_form_for(record, options = {}, &block)
    simple_form_for(record, options.deep_merge(wrapper: :essentials, wrapper_mappings: WRAPPER_MAPPINGS), &block)
  end

  # The error summary that sits above a form. Named the field, has role="alert", and links
  # each message to its input so a keyboard user can jump straight to the problem.
  def essentials_error_summary(record)
    return if record.blank? || record.errors.empty?

    # `data-error-summary` is the stable hook, the counterpart to the flash strip's `data-flash`.
    # Specs used to reach for the flash to assert a validation failure, because that is where the
    # message was; it is here now and they need something to hold on to that is not a class.
    # Glyph in its own column, heading and list in the next, so the list aligns under the
    # heading's text rather than under the glyph. The alignment is structural: no padding tuned
    # to the width of an icon, which is a number that goes stale the moment the type scale moves.
    #
    # `tabindex: -1` so `error_summary_controller` can put focus here when the form comes back
    # failed: on a full page re-render the browser leaves focus on <body>, and `role="alert"` is
    # defined in terms of a subtree *changing*, which is not what happens when the region is
    # already in the markup as the page loads. -1 and not 0 -- it is not a tab stop, only a
    # target for script.
    #
    # The live region is the inner div, not this one. Focusing an element that is itself
    # `role="alert"` is what reads the same content twice on several screen readers; the GOV.UK
    # error summary wraps its contents for the same reason.
    # The focus ring is the app's, not the browser's. Chrome matches `:focus-visible` on a
    # programmatic focus here and paints its own 1px outline; design.md asks for
    # `outline-2 outline-offset-2` in `brand-600` on everything that takes focus, and a summary the
    # page has just jumped to is exactly when a keyboard user needs to see where they landed.
    tag.div(class: "mb-5 flex gap-2.5 rounded-2xl border border-rose-200 bg-rose-50 px-4 py-3 " \
                   "focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-brand-600",
      tabindex: "-1", data: {error_summary: true, controller: "error-summary"}) do
      # A plain glyph, not an icon tile. The inline field errors sit on white and give theirs a
      # rose-50 chip; this one sits on a rose-50 surface, where a rose-50 tile is invisible --
      # design.md says exactly that about the flash bar, and a summary is the same kind of
      # object. It was built as a tile first and the tile could not be seen.
      concat tag.i(nil, class: "bi-exclamation-triangle mt-px shrink-0 text-sm text-rose-600",
        aria: {hidden: true})
      concat(tag.div(class: "min-w-0", role: "alert") do
        # The words are slate, not rose. The tinted surface and the glyph already say "this
        # failed"; colouring the sentences too is the same signal a third time, and slate-900 on
        # rose-50 is 16.25:1 where rose-900 is 8.71:1. What is red is the frame and the mark.
        concat tag.p("#{pluralize(record.errors.count, "error")} prevented this from being saved:",
          class: "text-sm font-semibold text-slate-900")
        # Plain text, not links. These were anchors to each field -- the GOV.UK pattern -- and
        # they read as blue underlined links dropped into a red box, because that is what they
        # were. Two things were wrong with that. design.md already says a link that is its own
        # block, "a table cell, a list item, a card row", takes no underline, and these are list
        # items; and a summary styled as a link list is Ruby for Good's odd one out, where
        # Polaris, Carbon and Atlassian all use a plain bulleted list under a bold line.
        #
        # Losing the jump costs little here: every one of these messages is also printed at its
        # own field, tied to the input by aria-describedby, so the summary says what is wrong and
        # the field says where. Restore the anchors only if a form gets long enough that
        # scrolling to the field is real work.
        concat(tag.ul(class: "mt-1.5 list-disc space-y-1 ps-5 text-sm text-slate-700") do
          safe_join(record.errors.map { |error| tag.li(error.full_message) })
        end)
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

  # What a control *looks* like -- border, radius, surface, focus ring -- with no size and no
  # layout in it, so a toolbar select and a stacked form field can share the look without one
  # inheriting the other's shape.
  CONTROL_SURFACE_CLASSES = "rounded-lg border border-slate-300 bg-white text-slate-900 " \
                            "shadow-sm focus:border-brand-500 focus:ring-2 " \
                            "focus:ring-brand-500/30 focus:outline-none"

  FILTER_CONTROL_BASE = "mt-1.5 block w-full py-2 text-sm #{CONTROL_SURFACE_CLASSES}"

  # Text inputs and date pickers: even padding.
  FILTER_CONTROL_CLASSES = "#{FILTER_CONTROL_BASE} px-3"

  # Selects: `pr-10` reserves room so the longest option ("Recertification required (1)") does
  # not run under the chevron, and `.select-chevron` replaces the native arrow with one we can
  # position -- the native one sits 4px from the border whatever the padding says.
  #
  # Named `SELECT_CLASSES`, not `FILTER_SELECT_CLASSES`, and the CSS class is `select-chevron`,
  # not `filter-select`. Both used to say "filter", and both were wrong about most of the app's
  # dropdowns: the chevron belongs to every select, and the ones outside a filter bar are the
  # majority. Use it for any `select_tag` or `f.select` that simple_form does not build.
  SELECT_CLASSES = "#{FILTER_CONTROL_BASE} select-chevron pl-3 pr-10"

  # A select that sits *in a row of buttons* rather than stacked under a label in a form. Every
  # other select in this app is a form field: `mt-1.5 block w-full`, which in a toolbar means full
  # width, a stray top margin, and 38px against its neighbours' 30px. This is the same surface and
  # the same `.select-chevron`, sized to `BUTTON_SIZES` so the row lines up.
  #
  # `pr-10` at both sizes on purpose -- the chevron is positioned from the right edge, not from the
  # padding, so shrinking the padding would slide the text under it rather than move it.
  INLINE_SELECT_SIZES = {
    sm: "py-1.5 pl-2.5 pr-10 text-xs",
    md: "py-2 pl-3 pr-10 text-sm"
  }.freeze

  def essentials_inline_select_classes(size: :md, extra: nil)
    [
      CONTROL_SURFACE_CLASSES,
      "select-chevron w-auto",
      INLINE_SELECT_SIZES.fetch(size.to_sym),
      extra
    ].compact.join(" ")
  end

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
        include_blank: true, class: SELECT_CLASSES, id: id)
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
    (help_link_path == help_path) ? "Help" : "User guide"
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
  # It renders for any table that has rows, including one that fits on a single page -- the
  # count is the point, and a card that grows and loses a footer depending on how much data
  # happens to be in it is a card of no fixed shape.
  #
  # It returns nil -- not an empty string -- when there is nothing to count, so the card skips
  # the footer instead of drawing an empty bordered strip under an empty state. Call sites used
  # to do `capture { concat(render(...)) }` and let the card test the result for blankness,
  # which worked in production and failed in development: annotate_rendered_view_with_filenames
  # puts an HTML comment in the buffer, so the "blank" capture was never blank.
  def essentials_pagination_footer(collection, page_params: {})
    return nil unless collection.respond_to?(:total_pages)
    return nil if collection.total_count.zero?

    render "shared/essentials/pagination", collection: collection, page_params: page_params
  end

  # "Showing 31–45 of 272 requests" — the range and the total, not the page number.
  #
  # A page number is a proxy. It changes meaning whenever the page size does, and it never
  # answers the question the filter bar above it raises: how big is this result set? Someone
  # looking at "Page 3 of 19" cannot tell whether the filter matched 140 records or 1,400.
  # Stripe, Shopify Admin, GitHub's issue lists and Django admin all put the range here.
  def essentials_pagination_summary(collection)
    first = collection.offset_value + 1
    last = collection.offset_value + collection.length
    total = collection.total_count

    safe_join([
      "Showing ",
      tag.span("#{number_with_delimiter(first)}–#{number_with_delimiter(last)}", class: "font-medium text-slate-900"),
      " of ",
      tag.span(number_with_delimiter(total), class: "font-medium text-slate-900"),
      " #{essentials_entry_name(collection, total)}"
    ])
  end

  # The noun, pluralised and in sentence case: "requests", "base items", "product drives".
  # Kaminari's `entry_name` gives the humanised model name, which is capitalised and which an
  # i18n entry may have set by hand — `ProductDrive` reads "Product Drive". A word keeps its
  # case if it carries an internal capital, so "NDBN member" does not become "ndbn member".
  def essentials_entry_name(collection, count)
    name = collection.respond_to?(:entry_name) ? collection.entry_name(count: count) : "result"

    # Force the number rather than trusting the `count:` that was just passed. A model name set
    # in the locale file as a plain string -- `product_drive: "Product Drive"` in en.yml -- comes
    # back unpluralised whatever count it is given, because Rails only pluralises a locale entry
    # written as a one/other hash. /product_drives read "Showing 1-2 of 2 product drive".
    name = (count == 1) ? name.singularize : name.pluralize

    name.split.map { |word| /\p{Lu}.*\p{Lu}/.match?(word) ? word : word.downcase }.join(" ")
  end
end
