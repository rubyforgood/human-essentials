# Provides full CRUD for Partners. These are minimal representations of corresponding Partner records in PartnerBase.
# Though the functionality of Partners is actually fleshed out in PartnerBase, in HumanEssentails, we maintain a collection
# of which Partners are associated with which Diaperbanks.
class PartnersController < ApplicationController
  include Importable
  before_action :validate_user_role, only: :show

  def index
    @unfiltered_partners_for_statuses = Partner.where(organization: current_organization)
    @partners = Partner.includes(:partner_group).where(organization: current_organization)
    @partners = if filter_params.empty?
      @partners.active
    else
      @partners.class_filter(filter_params)
    end
    @partners = @partners.alphabetized
    @partner_groups = PartnerGroup.includes(:partners, :item_categories).where(organization: current_organization)

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

  def invite_and_approve
    # Invite the partner
    partner = current_organization.partners.find(params[:id])

    partner_invite_service = PartnerInviteService.new(partner: partner, force: true)
    partner_invite_service.call

    # If no errors inviting, then approve the partner
    if partner_invite_service.errors.none?
      partner_approval_service = PartnerApprovalService.new(partner: partner)
      partner_approval_service.call

      if partner_approval_service.errors.none?
        redirect_to partners_path, notice: "Partner invited and approved!"
      else
        redirect_to partners_path, error: "Failed to approve partner because: #{partner_approval_service.errors.full_messages}"
      end
    else
      redirect_to partners_path, notice: "Failed to invite #{partner.name}! #{partner_invite_service.errors.full_messages}"
    end
  end

  def show
    @partner = current_organization.partners.find(params[:id])
    @impact_metrics = @partner.impact_metrics unless @partner.uninvited?
    @partner_distributions = @partner.distributions.includes(:partner, :storage_location, line_items: [:item]).order("issued_at DESC")
    @partner_profile_fields = current_organization.partner_form_fields
    @partner_users = @partner.users.order(name: :asc)

    respond_to do |format|
      format.html
      format.csv do
        send_data Exports::ExportDistributionsCSVService.new(distributions: @partner_distributions, filters: filter_params).generate_csv, filename: "PartnerDistributions-#{Time.zone.today}.csv"
      end
    end
  end

  def new
    @partner = current_organization.partners.new
    @partner_groups = current_organization.partner_groups
  end

  def edit
    @partner = current_organization.partners.find(params[:id])
    @partner_groups = PartnerGroup.where(organization: current_organization)
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
    partner = current_organization.partners.find(params[:id])
    if partner
      partner.destroy
      redirect_to partners_path, notice: "Deleted #{partner.name}"
    else
      redirect_to partners_path, alert: "Could not find partner to delete!"
    end
  end

  def invite
    partner = current_organization.partners.find(params[:id])

    svc = PartnerInviteService.new(partner: partner, force: true)
    svc.call

    if svc.errors.none?
      redirect_to partners_path, notice: "Partner #{partner.name} invited!"
    else
      redirect_to partners_path, notice: "Failed to invite #{partner.name}! #{svc.errors.full_messages}"
    end
  end

  def invite_partner_user
    partner = current_organization.partners.find(params[:partner])
    UserInviteService.invite(email: params[:email],
      roles: [Role::PARTNER],
      resource: partner)

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

  def validate_user_role
    if current_role.name == "partner"
      redirect_to partner_user_root_path,
        error: "You must be logged in as the essentials bank's organization administrator to approve partner applications."
    end
  end

  def partner_params
    params.require(:partner).permit(:name, :email, :send_reminders, :quota,
      :notes, :partner_group_id, :default_storage_location_id, documents: [])
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_status)
  end
end
