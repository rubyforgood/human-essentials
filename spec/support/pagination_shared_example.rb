shared_examples_for "pagination" do
    let(:model_f) { described_class.to_s.underscore.to_sym }

    describe "#index" do
        context "initialized with 100 records" do

            it "says it has 100 records" do
                multiple_instances_of_object = create_list(model_f, 100)
                expect(multiple_instances_of_object.size).to eq(100)
            end

            it "should default to #{Kaminari.config.default_per_page} records per page" do
            puts "==="
            puts current_path
            puts "==="
            end

    #         # it "allows user to jump to a different page" do
    #         # end
        end
    end
end
