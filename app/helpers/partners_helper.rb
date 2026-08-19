# Encapsulates methods that need some business logic
module PartnersHelper
  def display_requested_items(partner, child)
    ids = child.requested_item_ids
    ids.map do |item_id|
      partner.organization.item_id_to_display_string_map[item_id]
    end.join(', ')
  end

  def show_header_column_class(partner, additional_classes: "")
    if partner.quota.present?
      "col-sm-3 col-3 #{additional_classes}"
    else
      "col-sm-4 col-4 #{additional_classes}"
    end
  end

  def humanize_boolean(boolean)
    boolean ? 'Yes' : 'No'
  end

  def humanize_boolean_3state(boolean)
    if boolean.nil?
      "Unspecified"
    else
      boolean ? 'Yes' : 'No'
    end
  end

  # In step-wise editing of the partner profile, the partial name is used as the section header by default.
  # This helper allows overriding the header with a custom display name if needed.
  # Organization::ALL_PARTIALS already pairs each key with its display name and is what the
  # settings select shows, so it is the source here too. Humanizing separately is how the
  # accordion came to say "Pick up person" while the select said "Pick-up person".
  def partial_display_name(partial)
    custom_names = {"attached_documents" => "Additional documents"}
    from_constant = Organization::ALL_PARTIALS.find { |_label, key| key == partial.to_s }&.first
    custom_names[partial.to_s] || from_constant || partial.to_s.humanize
  end

  def section_with_errors?(section, sections_with_errors = [])
    sections_with_errors.include?(section)
  end

  def partner_status_badge(partner)
    if partner.status == "approved"
      tag.span partner.display_status, class: %w(badge badge-pill badge-primary bg-primary float-right)
    elsif partner.status == "recertification_required"
      tag.span partner.display_status, class: %w(badge badge-pill badge-danger bg-danger float-right)
    else
      tag.span partner.display_status, class: %w(badge badge-pill badge-info bg-info float-right)
    end
  end

  # Design system status pill for a partner. One mapping, used by the partner list, the
  # partner row and the dashboard, so the six states cannot drift apart. Tone only: the pill
  # stopped rendering an icon when it turned out six of them in one column read as clutter,
  # and dead icon names in here would be the next person's red herring.
  #
  # Tone answers "who is blocked?", not "how serious does the word sound?". Only
  # `awaiting_review` is the bank's move, so it is the only one that carries a warning tone --
  # any colour in the status column means someone here has to act. `invited` and
  # `recertification_required` are both waiting on the partner, so they share the informational
  # tone. `approved` is the goal state and the majority of rows; a badge on the norm spends
  # colour on what the reader can already see, and teaches them to skip the column.
  ESSENTIALS_PARTNER_STATUS = {
    "uninvited" => {tone: :neutral},
    "invited" => {tone: :info},
    "awaiting_review" => {tone: :warning},
    "approved" => {tone: :neutral},
    "recertification_required" => {tone: :info},
    "deactivated" => {tone: :neutral}
  }.freeze

  # No icon. Every row in the partner list carries one of these, so six icons stack up in a
  # single column and read as clutter -- and they are decorative: the word is what carries the
  # meaning, which is also what keeps the pill from depending on colour alone. Icons still earn
  # their place on pills that mark an exception ("Inactive", "Expired"), where they are rare.
  def essentials_partner_status_pill(status)
    config = ESSENTIALS_PARTNER_STATUS[status.to_s] || {tone: :neutral}
    essentials_status_pill(status.to_s.humanize, tone: config[:tone])
  end

  def partner_status_label(status)
    status_options = {
      "uninvited" => {icon: "exclamation-circle"},
      "invited" => {icon: "check", type: "info"},
      "awaiting_review" => {icon: "check", type: "warning"},
      "approved" => {icon: "check", type: "success"},
      "recertification_required" => {icon: "minus", type: "danger"},
      "deactivated" => {icon: "minus", type: "secondary"}
    }
    return content_tag :span, "Errored", class: "label label-teal" unless status_options[status]

    status_label(
      status.humanize,
      status_options[status][:icon],
      status_options[status][:type] || "default"
    )
  end
end
