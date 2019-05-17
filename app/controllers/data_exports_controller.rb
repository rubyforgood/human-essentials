# Provides a pseudo-resource for `DataExport`, a service object that encapsulates exporting functions.
class DataExportsController < ApplicationController
  respond_to :csv

  def csv
    type = params[:type]

    if DataExport.supported_types.include? type
      respond_to do |format|
        format.csv { send_data data(type), filename: "#{type}-#{Time.zone.today}.csv" }
      end
    end
  end

  private

  def data(type)
    DataExport.new(current_organization, type).as_csv
  end
end
