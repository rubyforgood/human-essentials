module Exportable
  extend ActiveSupport::Concern

  class_methods do
    def csv_export_headers
      raise 'not implemented'
    end

    def csv_export(data)
      [csv_export_headers] + data.map(&:csv_export_attributes)
    end
  end

  def csv_export_attributes
    raise 'not implemented'
  end
end
