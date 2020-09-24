module RequestsHelper
  def quota_display(partner)
    return "" if partner.quota.blank?

    "(#{partner.quota})"
  end

  def quota_column_class(total, partner)
    return "" if partner.quota.blank? || total.to_i < partner.quota

    "font-italic font-weight-bold"
  end
end
