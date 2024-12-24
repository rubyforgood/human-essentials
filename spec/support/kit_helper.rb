def create_kit(name: nil, active: true, organization: create(:organization), line_items_attributes: nil)
  params = FactoryBot.attributes_for(:kit, active: active)
  params[:name] = name if name

  params[:line_items_attributes] = (line_items_attributes || [
      {item_id: create(:item, organization: organization).id, quantity: 1}
    ])

  KitCreateService.new(organization_id: organization.id, kit_params: params).call.kit
end
