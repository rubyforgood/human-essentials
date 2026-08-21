require "rails_helper"

# The pager's label. Both of these have been silently wrong once: the noun did not pluralise for
# a model whose name is overridden in the locale file, and the range was computed from the page
# size rather than the rows, which is only right until the last page.
RSpec.describe EssentialsUiHelper, type: :helper do
  let(:organization) { create(:organization) }

  def summary_for(collection)
    helper.essentials_pagination_summary(collection).to_str.gsub(/<[^>]+>/, "").squish
  end

  describe "#essentials_pagination_summary" do
    before { create_list(:purchase, 7, organization: organization) }

    it "states the range and the total, not the page number" do
      collection = organization.purchases.page(1).per(3)

      expect(summary_for(collection)).to eq("Showing 1–3 of 7 purchases")
    end

    it "counts the last page from its rows, not from the page size" do
      collection = organization.purchases.page(3).per(3)

      expect(summary_for(collection)).to eq("Showing 7–7 of 7 purchases")
    end

    it "delimits a total large enough to need it" do
      collection = organization.purchases.page(1).per(3)
      allow(collection).to receive(:total_count).and_return(1400)

      expect(summary_for(collection)).to include("of 1,400 purchases")
    end

    it "marks up the numbers and leaves the words plain" do
      collection = organization.purchases.page(1).per(3)

      expect(helper.essentials_pagination_summary(collection))
        .to include('<span class="font-medium text-slate-900">1–3</span>')
    end
  end

  describe "#essentials_entry_name" do
    it "pluralises a model whose name the locale file overrides as a plain string" do
      # `product_drive: "Product Drive"` in en.yml is a String, so model_name.human(count: 2)
      # hands it back unchanged and the label read "2 product drive".
      collection = organization.product_drives.page(1)

      expect(helper.essentials_entry_name(collection, 2)).to eq("product drives")
      expect(helper.essentials_entry_name(collection, 1)).to eq("product drive")
    end

    it "lowercases an ordinary name" do
      collection = organization.purchases.page(1)

      expect(helper.essentials_entry_name(collection, 4)).to eq("purchases")
    end

    it "leaves an acronym alone" do
      # /admin/ndbn_members is not paginated yet; when it is, it must not read "ndbn members".
      collection = NDBNMember.page(1)

      expect(helper.essentials_entry_name(collection, 3)).to eq("NDBN members")
    end

    it "uses Kaminari's neutral noun for a collection with no model behind it" do
      expect(helper.essentials_entry_name(Kaminari.paginate_array([1, 2]).page(1), 2)).to eq("entries")
    end
  end
end
