class Admin::BroadcastAnnouncementsController < AdminController
  before_action :set_broadcast_announcement, only: %i[edit update destroy]
  before_action :require_admin

  def require_admin
    verboten! unless current_user.has_role?(Role::SUPER_ADMIN)
  end

  def index
    @broadcast_announcements = BroadcastAnnouncement.where(organization_id: nil)
  end

  def new
    @broadcast_announcement = BroadcastAnnouncement.new
  end

  def edit
  end

  def create
    @broadcast_announcement = BroadcastAnnouncement.new(broadcast_announcement_params)

    respond_to do |format|
      if @broadcast_announcement.save
        format.html { redirect_to admin_broadcast_announcements_url, notice: "Broadcast announcement was successfully created." }
      else
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @broadcast_announcement.update(broadcast_announcement_params)
        format.html { redirect_to admin_broadcast_announcements_url, notice: "Broadcast announcement was successfully updated." }
      else
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @broadcast_announcement.destroy

    respond_to do |format|
      format.html { redirect_to admin_broadcast_announcements_url, notice: "Broadcast announcement was successfully destroyed." }
    end
  end

  private

  def set_broadcast_announcement
    @broadcast_announcement = BroadcastAnnouncement.find(params[:id])
  end

  def broadcast_announcement_params
    params.require(:broadcast_announcement).permit(:user_id, :organization_id, :message, :link, :expiry)
  end
end
