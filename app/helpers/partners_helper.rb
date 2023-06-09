# Encapsulates methods that need some business logic
module PartnersHelper
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

  def partner_status_badge(partner)
    if partner.status == "approved"
      tag.span partner.display_status, class: %w(badge badge-pill badge-primary float-right)
    elsif partner.status == "recertification_required"
      tag.span partner.display_status, class: %w(badge badge-pill badge-danger float-right)
    else
      tag.span partner.display_status, class: %w(badge badge-pill badge-info float-right)
    end
  end
end
