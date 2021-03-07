module Partners
  class BaseController < ApplicationController
    before_action :redirect_to_root, unless: -> { Rails.env.test? || Flipper.enabled?(:onebase) }
    skip_before_action :authenticate_user!
    skip_before_action :authorize_user
    before_action :authenticate_partner_user!

    private

    def redirect_to_root
      redirect_to root_path
    end

    helper_method :current_partner
    def current_partner
      current_partner_user.partner
    end

    helper_method :valid_items
    def valid_items
      # @valid_items ||= DiaperBankClient.get_available_items(current_partner.diaper_bank_id)
      @valid_items ||= current_partner.organization.valid_items
    end

    helper_method :item_id_to_display_string_map
    def item_id_to_display_string_map
      @item_id_to_display_string_map ||= valid_items.each_with_object({}) do |item, hash|
        # hash[item["id"].to_i] = item["name"]
        hash[item[:id].to_i] = item[:name]
      end
    end

    # Copied from partner's application_helper.rb
    # https://github.com/rubyforgood/partner/blob/c597ca849f0074d3b8a458e1950d19c4b3e6f4d0/app/helpers/application_helper.rb#L10-L12I
    helper_method :valid_items_for_select
    def valid_items_for_select(items)
      # items.map { |item| [item["name"], item["id"]] }.sort
      items.map { |item| [item[:name], item[:id]] }.sort
    end
  end
end
