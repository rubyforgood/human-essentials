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

  def partner_status_badge(partner)
    if partner.status == "approved"
      tag.span partner.display_status, class: %w(badge badge-pill badge-primary bg-primary float-right)
    elsif partner.status == "recertification_required"
      tag.span partner.display_status, class: %w(badge badge-pill badge-danger bg-danger float-right)
    else
      tag.span partner.display_status, class: %w(badge badge-pill badge-info bg-info float-right)
    end
  end
end
