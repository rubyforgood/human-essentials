module RequestsHelper
  def quota_display(partner)
    return "" if partner.quota.blank?

    "(#{partner.quota})"
  end
end
