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
    @partner = current_organization.partners.new(partner_params)
    if @partner.save
      redirect_to partners_path, notice: "Partner added!"
    else
      flash[:error] = "Something didn't work quite right -- try again?"
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
      format.csv { send_data Partner.generate_distributions_csv(@partner_distributions), filename: "PartnerDistributions-#{Time.zone.today}.csv" }
    end
  end

  def new
    @partner = current_organization.partners.new
  end

  def approve_partner
    @partner = current_organization.partners.find(params[:id])

    @partner_profile = @partner.profile
    # Ensure that the ActiveStorage records associated with the
    # partner are available on the primary DB. If we do not do this,
    # partners would be uploading files that the diaperbase application
    # cannot see.
    @partner_profile.sync_attachments_from_partnerbase!

    @agency = @partner_profile.export_hash
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
    partner.register_on_partnerbase
    redirect_to partners_path, notice: "#{partner.name} invited!"
  end

  def re_invite
    partner = current_organization.partners.find(params[:partner])
    partner.add_user_on_partnerbase(email: params[:email])
    redirect_to partner_path(partner), notice: "We have invited #{params[:email]} to #{partner.name}!"
  end

  def recertify_partner
    @partner = current_organization.partners.find(params[:id])
    response = DiaperPartnerClient.put(partner_id: @partner.id, status: "recertification_required")
    if response.is_a?(Net::HTTPSuccess)
      @partner.recertification_required!
      redirect_to partners_path, notice: "#{@partner.name} recertification successfully requested!"
    else
      redirect_to partners_path, error: "#{@partner.name} failed to update partner records"
    end
  end

  def deactivate
    @partner = current_organization.partners.find(params[:id])
    response = DiaperPartnerClient.put(partner_id: @partner.id, status: "deactivated")

    if response.is_a?(Net::HTTPSuccess) && @partner.update(status: "deactivated")
      redirect_to partners_path, notice: "#{@partner.name} successfully deactivated!"
    else
      redirect_to partners_path, error: "#{@partner.name} failed to deactivate!"
    end
  end

  def reactivate
    @partner = current_organization.partners.find(params[:id])

    if @partner.status != "deactivated"
      redirect_to(partners_path, error: "#{@partner.name} is not deactivated!") && return
    end

    response = DiaperPartnerClient.put(partner_id: @partner.id, status: "verified")
    if response.is_a?(Net::HTTPSuccess) && @partner.update(status: "approved")
      redirect_to partners_path, notice: "#{@partner.name} successfully reactivated!"
    else
      redirect_to partners_path, error: "#{@partner.name} failed to reactivate!"
    end
  end

  private

  def autovivifying_hash
    Hash.new { |ht, k| ht[k] = autovivifying_hash }
  end

  def partner_params
    params.require(:partner).permit(:name, :email, :send_reminders, :quota, :notes, documents: [])
  end

  helper_method \
    def filter_params
    return {} unless params.key?(:filters)

    params.require(:filters).permit(:by_status)
  end
end
