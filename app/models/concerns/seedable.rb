module Seedable
  ITEMS_BY_CATEGORY = {
    "Diapers - Adult Briefs" => [
      { name: "Adult Briefs (Large/X-Large)" },
      { name: "Adult Briefs (Medium/Large)" },
      { name: "Adult Briefs (Small/Medium)" },
      { name: "Adult Briefs (XXL)" }
    ],
    "Diapers - Childrens" => [
      { name: "Cloth Diapers (Plastic Cover Pants)" },
      { name: "Disposable Inserts" },
      { name: "Kids (Newborn)" },
      { name: "Kids (Preemie)" },
      { name: "Kids (Size 1)" },
      { name: "Kids (Size 2)" },
      { name: "Kids (Size 3)" },
      { name: "Kids (Size 4)" },
      { name: "Kids (Size 5)" },
      { name: "Kids (Size 6)" },
      { name: "Kids L/XL (60-125 lbs)" },
      { name: "Kids Pull-Ups (2T-3T)" },
      { name: "Kids Pull-Ups (3T-4T)" },
      { name: "Kids Pull-Ups (4T-5T)" },
      { name: "Kids S/M (38-65 lbs)" },
      { name: "Swimmers" }
    ],
    "Diapers - Cloth (Adult)" => [
      { name: "Adult Cloth Diapers (Large/XL/XXL)" },
      { name: "Adult Cloth Diapers (Small/Medium)" }
    ],
    "Diapers - Cloth (Kids)" => [
      { name: "Cloth Diapers (AIO's/Pocket)" },
      { name: "Cloth Diapers (Covers)" },
      { name: "Cloth Diapers (Prefolds & Fitted)" },
      { name: "Cloth Inserts (For Cloth Diapers)" },
      { name: "Cloth Swimmers (Kids)" }
    ],
    "Incontinence Pads - Adult" => [
      { name: "Adult Incontinence Pads" },
      { name: "Underpads (Pack)" }
    ],
    "Misc Supplies" => [
      { name: "Bed Pads (Cloth)" },
      { name: "Bed Pads (Disposable)" },
      { name: "Bibs (Adult & Child)" },
      { name: "Diaper Rash Cream/Powder" },
    ],
    "Training Pants" => [
      { name: "Cloth Potty Training Pants/Underwear" },
    ],
    "Wipes - Childrens" => [
      { name: "Wipes (Baby)" },
    ]
  }

  def seed_it!(org)
    ITEMS_BY_CATEGORY.each do |category, entries|
      entries.each do |entry|
        item = org.items.find_or_create_by!(name: entry[:name], organization: self)
        item.update_attributes(entry.except(:name).merge(category: category))
      end
    end
  end
end
