shared_examples_for "pagination" do
    let(:model_f) { described_class.to_s.underscore.to_sym }

    it "works" do
        create_list(:model_f, 100)
    end

end