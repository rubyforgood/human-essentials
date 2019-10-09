class RequestsSeeder

  def self.seed(organization)
    20.times.each do |count|
      status = count > 15 ? 'fulfilled' : 'pending'
      request_create(organization, status)
    end
  end

  def self.request_create(organization, status)
    Request.create(
      partner: random_record_for_org(organization, Partner),
      organization: organization,
      request_items: [{ "item_id" => Item.all.pluck(:id).sample, "quantity" => 3 },
                      { "item_id" => Item.all.pluck(:id).sample, "quantity" => 2 }],
      comments: "Urgent",
      status: status
    )
  end
end
