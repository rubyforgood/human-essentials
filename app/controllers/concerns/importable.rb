module Importable
  extend ActiveSupport::Concern

  included do
    helper_method :current_organization, :current_user
  end

  def import_csv
    if params[:file].present?
      data = File.read(params[:file].path, encoding: "BOM|UTF-8")
      resource_model.import_csv(data, current_organization.id)
      flash[:notice] = "#{resource_model_name_plural} were imported successfully!"
    else
      flash[:error] = "No file was attached!"
    end
    redirect_back(fallback_location: { action: :index, organization_id: current_organization })
  end

  private

  def resource_model
    controller_name.classify.constantize
  end

  def resource_model_name_plural
    controller_name.humanize
  end
end
