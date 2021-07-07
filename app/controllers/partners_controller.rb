# Provides full CRUD for Partners. These are minimal representations of corresponding Partner records in PartnerBase.
# Though the functionality of Partners is actually fleshed out in PartnerBase, in DiaperBase, we maintain a collection
# of which Partners are associated with which Diaperbanks.
class PartnersController < ApplicationController
  include Importable

  def index
    @unfiltered_partners_for_statuses = Partner.where(organization: current_organization)
    @partners = Partner.where(organization: current_organization).class_filter(filter_params).alphabetized

    respond_to do |format|
      format.html
      format.csv { send_data Partner.generate_csv(@partners), filename: "Partners-#{Time.zone.today}.csv" }
    end
  end

  def create
    svc = PartnerCreateService.new(organization: current_organization, partner_attrs: partner_params)
    svc.call

    @partner = svc.partner

    if svc.errors.none?
      redirect_to partners_path, notice: "Partner #{@partner.name} added!"
    else
      flash[:error] = "Failed to add partner due to: #{svc.errors.full_messages}"
      render action: :new
    end
  end

  def approve_application
    @partner = current_organization.partners.find(params[:id])

    svc = PartnerApprovalService.new(partner: @partner)
    svc.call

    if svc.errors.none?
      redirect_to partners_path, notice: "Partner approved!"
    else
      redirect_to partners_path, error: "Failed to approve partner because: #{svc.errors.full_messages}"
    end
  end

  def show
    @partner = current_organization.partners.find(params[:id])
    @impact_metrics = @partner.profile.impact_metrics unless @partner.uninvited?
    @partner_distributions = @partner.distributions.order(created_at: :desc)

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportDistributionsCSVService.new(distribution_ids: @partner_distributions.map(&:id)).generate_csv, filename: "PartnerDistributions-#{Time.zone.today}.csv"
      end
    end
  end

  def new
    @partner = current_organization.partners.new
  end

  def edit
    @partner = current_organization.partners.find(params[:id])
  end

  def update
    @partner = current_organization.partners.find(params[:id])
    if @partner.update(partner_params)
      redirect_to partner_path(@partner), notice: "#{@partner.name} updated!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
      render action: :edit
    end
  end

  def destroy
    current_organization.partners.find(params[:id]).destroy
    redirect_to partners_path
  end

  def invite
    partner = current_organization.partners.find(params[:id])

    svc = PartnerInviteService.new(partner: partner)
    svc.call

    if svc.errors.none?
      redirect_to partners_path, notice: "Partner #{partner.name} invited!"
    else
      redirect_to partners_path, notice: "Failed to invite #{partner.name}! #{svc.errors.full_messages}"
    end
  end

  def invite_partner_user
    partner = current_organization.partners.find(params[:partner])
    existing_partner_user = PartnerUser.find_by(email: params[:email], partner: partner.profile)
    if existing_partner_user
      existing_partner_user.invite!
    else
      PartnerUser.invite!(email: params[:email], partner: partner.profile)
    end

    redirect_to partner_path(partner), notice: "We have invited #{params[:email]} to #{partner.name}!"
  rescue StandardError => e
    redirect_to partner_path(partner), error: "Failed to invite #{params[:email]} to #{partner.name} due to: #{e.message}"
  end

  def recertify_partner
    @partner = current_organization.partners.find(params[:id])

    svc = PartnerRequestRecertificationService.new(partner: @partner)
    svc.call

    if svc.errors.none?
      flash[:success] = "#{@partner.name} recertification successfully requested!"
    else
      flash[:error] = "#{@partner.name} failed to update partner records"
    end

    redirect_to partners_path
  end

  def deactivate
    @partner = current_organization.partners.find(params[:id])

    svc = PartnerDeactivateService.new(partner: @partner)
    svc.call

    if svc.errors.none?
      redirect_to partners_path, notice: "#{@partner.name} successfully deactivated!"
    else
      redirect_to partners_path, error: "#{@partner.name} failed to deactivate due to: #{svc.errors.full_messages}"
    end
  end

  def reactivate
    @partner = current_organization.partners.find(params[:id])

    if @partner.status != "deactivated"
      redirect_to(partners_path, error: "#{@partner.name} is not deactivated!") && return
    end

    svc = PartnerReactivateService.new(partner: @partner)
    svc.call

    if svc.errors.none?
      redirect_to partners_path, notice: "#{@partner.name} successfully reactivated!"
    else
      redirect_to partners_path, error: "#{@partner.name} failed to reactivate due to: #{svc.errors.full_messages}"
    end
  end

  private

  def partner_params
    params.require(:partner).permit(:name, :email, :send_reminders, :quota, :notes, documents: [])
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_status)
  end
end
