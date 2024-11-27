class FixBadKits < ActiveRecord::Migration[7.1]
  def change
    return unless Rails.env.production?

    ids = [78, 204,189]
    kit_base_item =  BaseItem.find_or_create_by!({
                                                   name: 'Kit',
                                                   category: 'kit',
                                                   partner_key: 'kit'
                                                 })
    Kit.where(id: ids).each do |kit|
      result = ItemCreateService.new(
        organization_id: kit.organization.id,
        item_params: {
          name: kit.name,
          partner_key: kit_base_item.partner_key,
          kit_id: kit.id
        }
      ).call
      unless result.success?
        raise result.error
      end
    end
  end
end
