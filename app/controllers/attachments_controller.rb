class AttachmentsController < ApplicationController
  def destroy
    ActiveStorage::Attachment.find(params[:id])&.purge

    redirect_back fallback_location: partners_path
  end
end
