class AttachmentsController < ApplicationController
  # Only partner documents are deleted through this controller, and only for
  # partners belonging to the current organization.
  def destroy
    ActiveStorage::Attachment.find_by!(
      id: params[:id],
      name: "documents",
      record_type: "Partner",
      record_id: current_organization.partners.select(:id)
    ).purge

    redirect_back_or_to(partners_path)
  end
end
