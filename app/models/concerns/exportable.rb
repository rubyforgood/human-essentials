module Exportable
  extend ActiveSupport::Concern

  class_methods do
    # @return [Array<String>]
    def csv_export_headers
      raise 'not implemented'
    end

    # @param data [Array<ApplicationRecord>]
    # @return [Array<Array<String>>]
    def csv_export(data)
      [csv_export_headers] + data.map(&:csv_export_attributes)
    end

    # @param data [Array<ApplicationRecord>]
    # @param additional_headers [Array<String>]
    # @return [String]
    def generate_csv(data, additional_headers = [])
      CSV.generate(headers: true) do |csv|
        csv_data = data.map do |record|
          record.csv_export_attributes.map { |attr| normalize_csv_attribute(attr) }
        end
        ([csv_export_headers + additional_headers] + csv_data).each do |row|
          csv << row
        end
      end
    end

    # @param attr [BasicObject]
    # @return [String]
    def normalize_csv_attribute(attr)
      case attr
      when Array
        attr.join(',')
      else
        attr.to_s
      end
    end
  end

  # @return [Array<BasicObject>]
  def csv_export_attributes
    raise 'not implemented'
  end
end
