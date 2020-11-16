module Exportable
  extend ActiveSupport::Concern

  class_methods do
    def csv_export_headers
      raise 'not implemented'
    end

    def csv_export(data)
      [csv_export_headers] + data.map(&:csv_export_attributes)
    end

    def generate_csv(data, additional_headers = [])
      CSV.generate(headers: true) do |csv|
        ([csv_export_headers + additional_headers] + data.map(&:csv_export_attributes)).each do |row|
          csv << row
        end
      end
    end
  end

  def csv_export_attributes
    raise 'not implemented'
  end
end
