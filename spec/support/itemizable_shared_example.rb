shared_examples_for "itemizable" do
  let(:model_f) { described_class.to_s.underscore.to_sym }
  let(:organization) { create(:organization) }
  let(:item) { create(:item) }

  context ".line_items" do
    describe "combine!" do
      it "combines multiple line_items with the same item_id into a single record" do
        organization = create(:organization, :with_items)
        item = create(:item, organization: organization)
        storage_location = create(:storage_location, :with_items, item: item, organization: organization)
        obj = build(model_f, storage_location: storage_location, organization: organization)

        2.times { obj.line_items.build(item_id: item.id, quantity: 5) }

        obj.line_items.combine!
        # It's valid, right?
        expect(obj.save).to eq(true)
        # And there's only one kind of line_item??
        expect(obj.line_items.count).to eq(1)
        # But we totally have 10 instead of just 5?????
        expect(obj.line_items.first.quantity).to eq(10)
        # AND IT'S THE RIGHT KIND OF ITEM?!?!?!
        expect(obj.line_items.first.item_id).to eq(item.id)
      end

      it "incrementally combines line_items on donations that have already been created" do
        # Start with some items of one kind
        obj = build(model_f, :with_items, item: item, item_quantity: 10, organization: organization)
        obj.save
        # Add some additional of that item
        obj.line_items.build(item_id: item.id, quantity: 5)
        # Combine it!
        obj.line_items.combine!
        obj.save
        # Still only one kind?
        expect(obj.line_items.size).to eq(1)
        # But with the new total?
        expect(obj.line_items.first.quantity).to eq(15)
      end
    end

    describe "quantities_by_name" do
      let(:item1) { create(:item, name: "item1", organization: organization) }
      let(:item2) { create(:item, name: "item2", organization: organization) }

      subject do
        s = create(model_f)
        s.line_items << create(:line_item, model_f.to_sym, item: item1, quantity: 10)
        s.line_items << create(:line_item, model_f.to_sym, item: item2, quantity: 20)
        s
      end

      it "returns a hash of items with id, name, and quantity" do
        quantities = [{ item_id: item1.id,
                        name: item1.name,
                        quantity: 10 },
                      { item_id: item2.id,
                        name: item2.name,
                        quantity: 20 }]

        expect(subject.line_items.quantities_by_name.values).to match_array(quantities)
      end

      it "leaves out zero-quantitied items if requested" do
        subject.line_items.last.update(quantity: 0)
        quantities = [{ item_id: item1.id,
                        name: item1.name,
                        quantity: 10 }]

        expect(subject.line_items.quantities_by_name.values).to match_array(quantities)
      end
    end

    describe "sorted" do
      subject {
        storage_location = create(:storage_location, organization: organization)
        create(model_f, organization: organization, storage_location: storage_location)
      } # the class that includes the concern

      it "displays the items, sorted by name" do
        names = %w(abc def ghi)
        subject.line_items << create(:line_item, model_f.to_sym, item: create(:item, name: names[1]))
        subject.line_items << create(:line_item, model_f.to_sym, item: create(:item, name: names[0]))
        subject.line_items << create(:line_item, model_f.to_sym, item: create(:item, name: names[2]))
        # The default *shouldn't* be sorted
        expect(subject.line_items).not_to eq(subject.line_items.sorted)
        # But the sorted version should
        expect(subject.line_items.sorted.collect(&:item).collect(&:name)).to match_array(names)
      end
    end
    describe "total" do
      subject {
        storage_location = create(:storage_location, organization: organization)
        create(model_f, organization: organization, storage_location: storage_location)
      } # the class that includes the concern

      it "has an item total" do
        expect do
          2.times { subject.line_items << create(:line_item, model_f.to_sym, quantity: 5) }
        end.to change { subject.line_items.total }.by(10)
      end
    end
  end
end
