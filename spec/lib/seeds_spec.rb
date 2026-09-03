RSpec.describe Seeds do
  describe ".seed_base_items" do
    # `db/seeds.rb` calls this unguarded, so it runs on every `bin/rails db:seed` -- including on a
    # database that has been seeded before. It has to be safe to run twice.
    #
    # It was not. The call was `find_or_create_by!(name:, category:, partner_key:, created_at:
    # Time.zone.now, updated_at: Time.zone.now)`, and `find_or_create_by!` builds its lookup from
    # *every* attribute passed to it -- so "created at this exact instant" went into the WHERE
    # clause, no existing row could match it, and the find always fell through to a create that
    # tripped BaseItem's unscoped uniqueness on name and partner_key.
    it "is idempotent" do
      described_class.seed_base_items
      count_after_first = BaseItem.count
      expect(count_after_first).to be > 0

      expect { described_class.seed_base_items }.not_to raise_error
      expect(BaseItem.count).to eq(count_after_first)
    end

    it "does not duplicate or renumber the records it already made" do
      described_class.seed_base_items
      before = BaseItem.order(:partner_key).pluck(:partner_key, :name, :category)

      described_class.seed_base_items

      expect(BaseItem.order(:partner_key).pluck(:partner_key, :name, :category)).to eq(before)
    end

    it "creates the kit base item alongside the ones in base_items.json" do
      described_class.seed_base_items

      entries = JSON.parse(Rails.root.join("db", "base_items.json").read).values.sum(&:size)
      expect(BaseItem.count).to eq(entries + 1)
      expect(BaseItem.find_by(partner_key: "kit")).to be_present
    end
  end
end
