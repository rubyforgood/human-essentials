module RequestsHelper
  def quota_display(partner)
    return "" if partner.quota.blank?

    "(#{partner.quota})"
  end

  def quota_column_class(total, partner)
    return "" if partner.quota.blank? || total < partner.quota

    "text-danger font-weight-bold"
  end
end
