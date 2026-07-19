class AttachmentsController < ApplicationController
  def destroy
    ActiveStorage::Attachment.find(params[:id])&.purge

    redirect_back_or_to(partners_path)
  end
end
