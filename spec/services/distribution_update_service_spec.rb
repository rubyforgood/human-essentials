RSpec.describe DistributionUpdateService, type: :service do
  describe "call" do
    let!(:distribution) { FactoryBot.create(:distribution, :with_items, item_quantity: 10) }
    let!(:new_attributes) { { line_items_attributes: { "0": { item_id: distribution.line_items.first.item_id, quantity: 2 } } } }

    it "replaces a big distribution with a smaller one, resulting in increased stored quantities" do
      expect do
        DistributionUpdateService.new(distribution, new_attributes).call
      end.to change { distribution.storage_location.size }.by(8)
    end
  end

  describe "resend_notification?" do
    let!(:distribution) { FactoryBot.create(:distribution, :with_items, item_quantity: 10) }

    it "changes the issue_date, resulting in resend_notification? = true" do
      service = DistributionUpdateService.new(distribution, { issued_at: distribution.issued_at + 1.day })
      service.call
      assert service.resend_notification?
    end

    it "changes the delivery_method, resulting in resend_notification? = true" do
      service = DistributionUpdateService.new(distribution, { delivery_method: :delivery })
      service.call
      assert service.resend_notification?
    end

    it "changes any distribution content, resulting in resend_notification? = true" do
      new_distibution_params = {
        issued_at: distribution.issued_at,
        line_items_attributes: { "0": { item_id: distribution.line_items.first.item_id, quantity: 4 } },
        delivery_method: distribution.delivery_method
      }

      service = DistributionUpdateService.new(distribution, new_distibution_params)
      service.call
      assert service.resend_notification?
    end
  end
end
