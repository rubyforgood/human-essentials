class AttachmentsController < ApplicationController
  # Migrated to the Ruby for Good design system (ADR 0011).
  layout "essentials_app"

  def destroy
    ActiveStorage::Attachment.find(params[:id])&.purge

    redirect_back_or_to(partners_path)
  end
end
