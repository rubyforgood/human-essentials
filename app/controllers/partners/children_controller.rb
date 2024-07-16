require "csv"
module Partners
  class ChildrenController < BaseController
    layout 'partners/application'

    def index
      @filterrific = initialize_filterrific(
        current_partner.children
                       .includes(:family)
                       .order(sort_order),
        params[:filterrific]
      ) || return

      @children = @filterrific.find

      respond_to do |format|
        format.js
        format.html
        format.csv do
          send_data Partners::Child.generate_csv(@children), filename: "Children-#{Time.zone.today}.csv"
        end
      end
      @family = current_partner.children
                               .includes(:family)
                               .order(active: :desc, last_name: :asc).collect(&:family).compact.uniq.sort
    end

    def show
      @child = current_partner.children.find_by(id: params[:id])
      @child_item_requests = @child
                             .child_item_requests
                             .includes(:item_request)
    end

    def new
      family = current_partner.families.find_by!(id: params[:family_id])
      @child = family.children.new

      @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call
    end

    def active
      child = current_partner.children.find(params[:child_id])
      child.active = !child.active
      child.save
    end

    def edit
      @child = current_partner.children.find_by(id: params[:id])
      @requestable_items = PartnerFetchRequestableItemsService.new(partner_id: current_partner.id).call
    end

    def create
      family = current_partner.families.find_by!(id: params[:family_id])
      child = family.children.new(child_params)

      if child.save
        redirect_to child, notice: "Child was successfully created."
      else
        render :new
      end
    end

    def update
      child = current_partner.children.find_by(id: params[:id])

      if child.update(child_params)
        redirect_to child, notice: "Child was successfully updated."
      else
        render :edit
      end
    end

    private

    def child_params
      params.require(:partners_child).permit(
        :active,
        :agency_child_id,
        :comments,
        :date_of_birth,
        :first_name,
        :gender,
        :health_insurance,
        :last_name,
        :race,
        :archived,
        child_lives_with: [],
        requested_item_ids: []
      )
    end

    def sort_order
      sort_column + ' ' + sort_direction
    end

    helper_method :sort_direction # used in SortableHelper
    def sort_direction
      %w[asc desc].include?(params[:direction]) ? params[:direction] : "asc"
    end

    helper_method :sort_column # used in SortableHelper
    def sort_column
      Child.column_names.include?(params[:sort]) ? params[:sort] : "last_name"
    end

    helper_method :fetch_valid_item_name
    def fetch_valid_item_name(id)
      @valid_items ||= current_partner.organization.valid_items
      @valid_items.find { |vi| vi[:id] == id }&.fetch(:name)
    end
  end
end
