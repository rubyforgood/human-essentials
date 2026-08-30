RSpec.describe UiHelper, type: :helper do
  describe 'optional_data_text' do
    subject { helper.optional_data_text(field) }

    context 'when the field provided is not blank' do
      let(:field) { Faker::Name.first_name }

      it 'should return the content' do
        expect(subject).to match(/span/m)
        expect(subject).to include(field)
      end
    end

    context 'when the field provided is blank' do
      let(:field) { '' }

      it 'should return the text Not-Provided in gray text' do
        expect(subject).to match(/span/m)
        expect(subject).to include('Not-Provided')
        expect(subject).to include('text-muted font-weight-light')
      end
    end
  end

  describe 'add_element_button' do
    context "with default options" do
      subject { helper.add_element_button("Label", container_selector: "Container") { "Block" } }

      it 'should generate a button with correct attributes' do
        page = Nokogiri::HTML(subject).css("div").first
        expect(page).to_not be_nil

        button = page.css("a").first
        expect(button).to_not be_nil
        expect(button.attributes["class"].value).to eq("btn btn-md btn-primary")
        expect(button.attributes["data-form-input-target"].value).to eq("addButton")
        expect(button.attributes["data-add-dest-selector"].value).to eq("Container")
        expect(button.attributes["data-action"].value).to eq("click->form-input#addItem:prevent")
        expect(button.attributes["role"].value).to eq("button")
        expect(button.text.strip).to eq("Label")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("fa fa-plus")

        template = page.css("template").first
        expect(template).to_not be_nil
        expect(template.attributes["data-form-input-target"].value).to eq("addTemplate")
        expect(template.text).to eq("Block")
      end
    end

    context "with custom options" do
      subject {
        helper.add_element_button("Label", container_selector: "Container", class: "Class", id: "Id",
          data: {test: "test"}) { "Block" }
      }

      it 'should generate a button with correct attributes' do
        page = Nokogiri::HTML(subject).css("div").first
        expect(page).to_not be_nil

        button = page.css("a").first
        expect(button).to_not be_nil
        expect(button.attributes["class"].value).to eq("Class")
        expect(button.attributes["id"].value).to eq("Id")
        expect(button.attributes["data-test"].value).to eq("test")
        expect(button.attributes["data-form-input-target"]).to be_nil
        expect(button.attributes["data-add-dest-selector"]).to be_nil
        expect(button.attributes["data-action"]).to be_nil
        expect(button.attributes["role"].value).to eq("button")
        expect(button.text.strip).to eq("Label")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("fa fa-plus")

        template = page.css("template").first
        expect(template).to_not be_nil
        expect(template.attributes["data-form-input-target"].value).to eq("addTemplate")
        expect(template.text).to eq("Block")
      end
    end
  end

  describe 'remove_element_button' do
    context "with default options" do
      subject { helper.remove_element_button("Label", container_selector: "Container") }

      it 'should generate a button with correct attributes' do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button).to_not be_nil

        expect(button.attributes["class"].value).to eq("btn btn-md btn-danger")
        expect(button.attributes["data-action"].value).to eq("click->form-input#removeItem:prevent")
        expect(button.attributes["data-remove-parent-selector"].value).to eq("Container")
        expect(button.attributes["data-remove-soft"].value).to eq("false")
        expect(button.text.strip).to eq("Label")
        expect(button.attributes["role"].value).to eq("button")
        expect(button.attributes["href"].value).to eq("javascript:void(0)")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("fa fa-trash")
      end

      context 'when soft is false' do
        subject { helper.remove_element_button("Label", container_selector: "Container", soft: true) }

        it 'should generate a button with correct attributes' do
          button = Nokogiri::HTML(subject).css("a").first
          expect(button).to_not be_nil
          expect(button.attributes["data-remove-soft"].value).to eq("true")
        end
      end
    end

    context "with custom options" do
      subject { helper.remove_element_button("Label", container_selector: "Container", class: "test", data: {test: "test"}) }

      it 'should generate a button with correct attributes' do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button).to_not be_nil

        expect(button.attributes["class"].value).to eq("test")
        expect(button.attributes["data-action"]).to be_nil
        expect(button.attributes["data-remove-parent-selector"]).to be_nil
        expect(button.attributes["data-remove-soft"]).to be_nil
        expect(button.attributes["data-test"].value).to eq("test")
        expect(button.text.strip).to eq("Label")
        expect(button.attributes["role"].value).to eq("button")
        expect(button.attributes["href"].value).to eq("javascript:void(0)")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("fa fa-trash")
      end
    end
  end

  describe 'modal_button_to' do
    context 'with default options' do
      subject { helper.modal_button_to("#newRequest", text: "New Quantity Request", icon: "plus", type: "success") }

      it 'renders a link that toggles the Bootstrap modal' do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button).to_not be_nil
        expect(button.attributes["href"].value).to eq("#newRequest")
        expect(button.attributes["data-bs-toggle"].value).to eq("modal")
        expect(button.attributes["class"].value).to include("btn btn-success")
        expect(button.text.strip).to eq("New Quantity Request")
      end

      # Regression test for #5632: a modal-toggle button never navigates, so it must not carry
      # rails-ujs' `data-disable-with` attribute, otherwise it stays stuck on "Please wait..."
      # after the modal is dismissed.
      it 'does not set data-disable-with' do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button.attributes["data-disable-with"]).to be_nil
      end
    end

    context 'when the caller passes custom data' do
      subject { helper.modal_button_to("#newRequest", text: "New Quantity Request", data: {test: "test"}) }

      it 'keeps the custom data and still omits data-disable-with' do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button.attributes["data-test"].value).to eq("test")
        expect(button.attributes["data-bs-toggle"].value).to eq("modal")
        expect(button.attributes["data-disable-with"]).to be_nil
      end
    end
  end
end
