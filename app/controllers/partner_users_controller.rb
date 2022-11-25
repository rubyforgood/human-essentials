# frozen_String_literal: true

class PartnerUsersController < ApplicationController
  before_action :set_partner, only: %i[index create destroy resend_invitation]

  def index
    @users = @partner.profile.users
    @user = User.new(name: "")
  end

  def create
    user = UserInviteService.invite(email: user_params[:email], name: user_params[:name], roles: [Role::PARTNER], resource: @partner.profile)
    user.valid?

    respond_to do |format|
      format.turbo_stream do
        if user.errors.none?
          flash.now[:notice] = "#{user.name} has been invited. Invitation email sent to #{user.email}"

          render turbo_stream: [
            turbo_stream.replace("partners/#{@partner.id}/form", partial: "partner_users/form", locals: {partner: @partner, user: User.new(name: "")}),
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("partners/#{@partner.id}/users", partial: "partner_users/users", locals: {users: @partner.reload.profile.users, partner: @partner})
          ]
        else
          flash.now[:error] = "Invitation failed. Check the form for errors."
          render turbo_stream: [
            turbo_stream.replace("partners/#{@partner.id}/form", partial: "partner_users/form", locals: {partner: @partner, user: user}),
            turbo_stream.replace("flash", partial: "shared/flash")
          ], status: :bad_request
        end
      end
    end
  end

  def destroy
    user = User.find(params[:id])

    respond_to do |format|
      format.turbo_stream do
        if user.remove_role(Role::PARTNER, @partner.profile)
          flash.now[:notice] = "Access to #{user.name} has been revoked."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("partners/#{@partner.id}/users", partial: "partner_users/users", locals: {users: @partner.reload.profile.users, partner: @partner})
          ]
        else
          flash.now[:error] = "Invitation failed. Check the form for errors."
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash")
          ], status: :bad_request
        end
      end
    end
  end

  def resend_invitation
    user = User.find(params[:id])

    if user.invitation_accepted_at.nil?
      user.invite!
    else
      user.errors.add(:base, "User has already accepted invitation.")
    end

    respond_to do |format|
      format.turbo_stream do
        if user.errors.none?
          flash.now[:notice] = "Invitation email sent to #{user.email}"
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash"),
            turbo_stream.replace("partners/#{@partner.id}/users", partial: "partner_users/users", locals: {users: @partner.reload.profile.users, partner: @partner})
          ]
        else
          flash.now[:error] = user.errors.full_messages.to_sentence
          render turbo_stream: [
            turbo_stream.replace("flash", partial: "shared/flash")
          ], status: :bad_request
        end
      end
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
