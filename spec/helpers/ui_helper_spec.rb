RSpec.describe UiHelper, type: :helper do
  # These assert the helpers' CONTRACT -- the data attributes the Stimulus controllers read,
  # the role, the href, the label, the template -- rather than an exact class string. The
  # class string used to be `btn btn-md btn-primary`; pinning the new one just re-creates the
  # same brittleness against a different framework.
  describe "optional_data_text" do
    subject { helper.optional_data_text(field) }

    context "when the field provided is not blank" do
      let(:field) { Faker::Name.first_name }

      it "returns the content" do
        expect(subject).to match(/span/m)
        expect(subject).to include(field)
      end
    end

    context "when the field provided is blank" do
      let(:field) { "" }

      it "says so, in muted italic text" do
        expect(subject).to match(/span/m)
        expect(subject).to include("Not provided")
        expect(subject).to include("italic")
        expect(subject).to include("text-slate-500")
      end
    end
  end

  describe "add_element_button" do
    context "with default options" do
      subject { helper.add_element_button("Label", container_selector: "Container") { "Block" } }

      it "generates a button with the attributes the form-input controller reads" do
        page = Nokogiri::HTML(subject).css("div").first
        expect(page).to_not be_nil

        button = page.css("a").first
        expect(button).to_not be_nil
        expect(button.attributes["data-form-input-target"].value).to eq("addButton")
        expect(button.attributes["data-add-dest-selector"].value).to eq("Container")
        expect(button.attributes["data-action"].value).to eq("click->form-input#addItem:prevent")
        expect(button.attributes["role"].value).to eq("button")
        expect(button.text.strip).to eq("Label")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("bi-plus-lg")
        expect(icon.attributes["aria-hidden"].value).to eq("true")

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

      it "lets the caller replace the defaults" do
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

        template = page.css("template").first
        expect(template).to_not be_nil
        expect(template.attributes["data-form-input-target"].value).to eq("addTemplate")
        expect(template.text).to eq("Block")
      end
    end
  end

  describe "remove_element_button" do
    context "with default options" do
      subject { helper.remove_element_button("Label", container_selector: "Container") }

      it "generates a button with the attributes the form-input controller reads" do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button).to_not be_nil

        expect(button.attributes["data-action"].value).to eq("click->form-input#removeItem:prevent")
        expect(button.attributes["data-remove-parent-selector"].value).to eq("Container")
        expect(button.attributes["data-remove-soft"].value).to eq("false")
        expect(button.text.strip).to eq("Label")
        expect(button.attributes["role"].value).to eq("button")
        expect(button.attributes["href"].value).to eq("javascript:void(0)")

        icon = button.css("i").first
        expect(icon).to_not be_nil
        expect(icon.attributes["class"].value).to eq("bi-trash")
      end

      context "when soft is true" do
        subject { helper.remove_element_button("Label", container_selector: "Container", soft: true) }

        it "marks the removal as soft" do
          button = Nokogiri::HTML(subject).css("a").first
          expect(button).to_not be_nil
          expect(button.attributes["data-remove-soft"].value).to eq("true")
        end
      end
    end

    context "with custom options" do
      subject { helper.remove_element_button("Label", container_selector: "Container", class: "test", data: {test: "test"}) }

      it "lets the caller replace the defaults" do
        button = Nokogiri::HTML(subject).css("a").first
        expect(button).to_not be_nil

        expect(button.attributes["class"].value).to eq("test")
        expect(button.attributes["data-action"]).to be_nil
        expect(button.attributes["data-remove-parent-selector"]).to be_nil
        expect(button.attributes["data-remove-soft"]).to be_nil
        expect(button.attributes["data-test"].value).to eq("test")
        expect(button.text.strip).to eq("Label")
      end
    end
  end

  describe "an unavailable action" do
    # A link cannot be disabled: it stays focusable and clickable by keyboard and announces
    # nothing. `enabled: false` therefore renders a non-interactive span, not a dead <a>.
    it "renders a link action as a non-interactive span" do
      html = Nokogiri::HTML(helper.edit_button_to("/somewhere", enabled: false))
      expect(html.css("a")).to be_empty
      expect(html.at_css("span")).to be_present
      expect(html.at_css("span").attributes["aria-disabled"].value).to eq("true")
    end

    it "renders a form action as a disabled button" do
      html = Nokogiri::HTML(helper.deactivate_button_to("/somewhere", enabled: false))
      expect(html.at_css("button").attributes["disabled"]).to be_present
    end
  end
end
