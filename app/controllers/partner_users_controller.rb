# frozen_String_literal: true

class PartnerUsersController < ApplicationController
  before_action :set_partner, only: %i[index create]

  def index
    @users = @partner.profile.users
    @user = User.new
  end

  def create
    svc = UserInviteService.invite(email: user_params[:email], roles: [Role::PARTNER], resource: @partner)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.replace('partner_users/new/form', partial: 'partner_users/form', locals: { partner: @partner, user: User.new }),
          turbo_stream.replace("partners/#{@partner.id}/index", partial: 'partner_users/index', locals: { partner: @partner })
        ]
      end
    end
  end

  private

  def set_partner
    @partner = Partner.find(params[:partner_id])
  end

  def user_params
    params.require(:user).permit(:email)
  end


end
