# Importable adds an `import_csv` action that that responds to routes like this:
#
#  resources :storage_locations do
#    collection do
#      post :import_csv
#    end
#  end
#
# If the model doing the import doesn't match the controller's name, you
# should update the add a `resource_model` method and to override the default
# class, e.g.
#
#  class Admin::LocationsController
#    def resource_model
#      Location
#    end
#  end
module Importable
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :current_user
  end

  def import_csv
    if params[:file].present?
      data = File.read(params[:file].path, encoding: "BOM|UTF-8")
      csv = CSV.parse(data, headers: true, skip_blanks: true)
      if csv.count.positive? && csv.first.headers.all? { |header| !header.nil? }
        errors = resource_model.import_csv(csv, current_organization.id)
        if errors.empty?
          flash[:notice] = "#{resource_model_humanized} were imported successfully!"
        else
          flash[:error] = "The following #{resource_model_humanized} did not import successfully:\n#{errors.join("\n")}"
        end
      else
        flash[:error] = "Check headers in file!"
      end
    else
      flash[:error] = "No file was attached!"
    end
    redirect_back(fallback_location: { action: :index, organization_id: current_organization })
  end

  private

  def resource_model
    controller_name.classify.constantize
  end

  def resource_model_humanized
    controller_name.humanize
  end
end
