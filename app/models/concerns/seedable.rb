module Seedable
  def seed_it!(org)
    CanonicalItem.all.each do |canonical_item|
      org.items.add_from_canonical(canonical_item) 
    end
  end
end
