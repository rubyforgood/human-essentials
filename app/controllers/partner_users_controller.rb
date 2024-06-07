# frozen_String_literal: true

class PartnerUsersController < ApplicationController
  before_action :set_partner, only: %i[index create destroy resend_invitation]

  def index
    @users = @partner.users
    @user = User.new(name: "")
  end

  def create
    @user = UserInviteService.invite(
      email: user_params[:email],
      name: user_params[:name],
      roles: [Role::PARTNER],
      resource: @partner
    )
    if @user.valid?
      redirect_back(fallback_location: "/",
        notice: "#{@user.name} has been invited. Invitation email sent to #{@user.email}")
    else
      flash[:alert] = "Invitation failed. Check the form for errors."
      @users = @partner.users
      render :index
    end
  end

  def destroy
    user = User.find(params[:id])

    if user.remove_role(Role::PARTNER, @partner)
      redirect_back(fallback_location: "/", notice: "Access to #{@partner.name} has been revoked for #{user.display_name}.")
    else
      redirect_back(fallback_location: "/", alert: "Invitation failed. Check the form for errors.")
    end
  end

  def resend_invitation
    user = User.find(params[:id])

    if user.invitation_accepted_at.nil?
      user.invite!
    else
      user.errors.add(:base, "User has already accepted invitation.")
    end

    if user.errors.none?
      redirect_back(fallback_location: "/", notice: "Invitation email sent to #{user.email}")
    else
      redirect_back(fallback_location: "/", alert: user.errors.full_messages.to_sentence)
    end
  end

  private

  def set_partner
    @partner = Partner.find(params[:partner_id])
  end

  def user_params
    params.require(:user).permit(:email, :name)
  end
end
