module Reports
  class OtherProductsReportService
    attr_reader :year, :organization

    def initialize(year:, organization:)
      @year = year
      @organization = organization
    end

    def report
      @report ||= {
        other_products: other_products
      }
    end

    def columns_for_csv
      %i[other_products]
    end

    def other_products
      organization.items.where(partner_key: other_products_partner_keys).map(&:name)
    end

    def base_item_json(key)
      file = File.read("db/base_items.json")
      json = JSON.parse(file)

      json[key].map(&:values).map { |keys| keys[0] }
    end

    def other_products_partner_keys
      menstrual_supplies = base_item_json("Menstrual Supplies/Items")
      miscellaneous = base_item_json("Miscellaneous")
      training_pants = base_item_json("Training Pants")
      wipes_adult = base_item_json("Wipes - Adults")
      wipes_children = base_item_json("Wipes - Childrens")

      menstrual_supplies + miscellaneous + training_pants + wipes_adult + wipes_children
    end
  end
end
