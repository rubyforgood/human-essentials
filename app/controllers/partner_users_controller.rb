# frozen_String_literal: true

class PartnerUsersController < ApplicationController
  before_action :set_partner, only: %i[index]

  def index
    @users = @partner.profile.users
  end

  private

  def set_partner
    @partner = Partner.find(params[:partner_id])
  end


end
