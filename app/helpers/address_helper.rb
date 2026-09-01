# Puts every state name ever into a single file, so we don't have to do it anywhere else.
#
# ...and, since 2026-09, one definition of what an address *field* is. Seven screens collected an
# address in five different shapes: `state` was a 52-option select on one and a free text box on
# another, `zip_code` was a string here and an integer there, the same box was labelled "Street",
# "Street address" and "Address (line 1)", and **not one of the 17 inputs carried `autocomplete`**.
# See "Address fields" in design.md.
module AddressHelper
  # The parts of a US address, each with the label the app uses and the WCAG 1.3.5 autocomplete
  # token the browser needs to fill it.
  #
  # The tokens are not interchangeable and are the whole point of the table: `street-address` is a
  # *multi-line* whole address, so a two-line address uses `address-line1` and `address-line2`
  # instead; `address-level2` is the city and `address-level1` the state, named by administrative
  # level rather than by country-specific words. WHATWG defines them, and Chrome, Safari and
  # Firefox all fill from them.
  ADDRESS_FIELDS = {
    street: {label: "Street address", autocomplete: "street-address"},
    line1: {label: "Address line 1", autocomplete: "address-line1"},
    line2: {label: "Address line 2", autocomplete: "address-line2"},
    city: {label: "City", autocomplete: "address-level2"},
    state: {label: "State", autocomplete: "address-level1"},
    zip: {label: "ZIP code", autocomplete: "postal-code"}
  }.freeze

  # A ZIP is five digits, or five and four. **Not a number**: `type="number"` drops the leading
  # zero on every ZIP in New England and Puerto Rico, refuses ZIP+4 outright, and puts a spinner on
  # a field nobody increments. `inputmode` still brings up the numeric keypad on a phone.
  ZIP_PATTERN = '\\d{5}(-\\d{4})?'

  # The options for one part of an address, ready to hand to simple_form.
  #
  #   f.input :zipcode, **address_field(:zip)
  #
  # Pass `label:` to override the wording where a screen genuinely needs different words -- the
  # partner profile's second address is a *program* address, not the agency's.
  # `third_party: true` for an address that is not the person filling the form in. WCAG 1.3.5 is
  # about "input fields that collect information about the user", and a partner typing a *client's*
  # ZIP is entering someone else's -- autofilling the caseworker's own address into a family record
  # would be worse than not filling it. It becomes `autocomplete="off"`, which is the standard way
  # to say so out loud; leaving the attribute off entirely says nothing, and an audit cannot tell
  # that apart from an oversight.
  def address_field(role, third_party: false, **overrides)
    spec = ADDRESS_FIELDS.fetch(role)
    input_html = {autocomplete: third_party ? "off" : spec[:autocomplete]}
    case role
    when :state
      return {label: spec[:label], collection: us_states, include_blank: true,
              input_html: input_html}.merge(overrides)
    when :zip
      input_html.merge!(inputmode: "numeric", pattern: ZIP_PATTERN, maxlength: 10,
        placeholder: "12345 or 12345-6789")
    end
    {label: spec[:label], input_html: input_html}.merge(overrides)
  end

  # The same thing as raw HTML attributes, for `f.input_field`, which takes attributes rather than
  # simple_form options and so renders no label of its own. `admin/organizations/edit` is the one
  # screen built that way: a stacked block of unlabelled boxes named by placeholder.
  #
  # The select takes no placeholder -- a `placeholder` attribute on a `<select>` does nothing at all
  # -- so it is named by its aria-label alone.
  def address_field_attrs(role)
    spec = ADDRESS_FIELDS.fetch(role)
    attrs = {autocomplete: spec[:autocomplete], aria: {label: spec[:label]}}
    return attrs if role == :state

    attrs[:placeholder] = spec[:label]
    if role == :zip
      attrs.merge!(inputmode: "numeric", pattern: ZIP_PATTERN, maxlength: 10,
        placeholder: "12345 or 12345-6789")
    end
    attrs
  end

  # The 50 states plus DC, as postal codes. A **constant**, not just the collection the
  # helper returns, because `StructuredAddress` parses addresses in the model layer and
  # needs to recognise a state code there -- and two copies of this list is how they
  # drift. `spec/helpers/address_helper_spec.rb` pins that there is only one.
  STATE_CODES = %w[
    AK AL AR AZ CA CO CT DC DE FL
    GA HI IA ID IL IN KS KY LA MA
    MD ME MI MN MO MS MT NC ND NE
    NH NJ NM NV NY OH OK OR PA RI
    SC SD TN TX UT VA VT WA WI WV
    WY
  ].freeze

  def us_states
    STATE_CODES.map { |code| [code, code] }
  end
end
