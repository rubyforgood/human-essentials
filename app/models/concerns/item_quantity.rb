# Expects methods `item` and `quantity`.
module ItemQuantity
  extend ActiveSupport::Concern

  def value_per_line_item
    (item&.value_in_cents || 0) * quantity
  end

  def has_packages
    quantity / item.package_size.to_f if item.package_size
  end

  def package_count
    format("%g", has_packages) if has_packages
  end
end
