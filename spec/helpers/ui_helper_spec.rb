require "rails_helper"

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

  describe 'input_add_button' do
    context "with default options" do
      subject { helper.input_add_button("Label", container_selector: "Container") { "Block" } }

      it 'should generate a button with correct attributes' do
        unsafe_html = CGI.unescapeHTML(subject)

        expect(unsafe_html).to match(/<div>/)
        expect(unsafe_html).to match(/<a.* class="btn btn-outline-primary".*>/)
        expect(unsafe_html).to match(/<a.* data-form-input-target="addButton".*>/)
        expect(unsafe_html).to match(/<a.* data-add-dest-selector="Container".*>/)
        expect(unsafe_html).to match(/<a.* data-action="click->form-input#addItem:prevent".*>/)
        expect(unsafe_html).to match(/<a.*>Label<\/a>/)
        expect(unsafe_html).to match(/<template.* data-form-input-target="addTemplate".*>/)
        expect(unsafe_html).to match(/<template.*>Block<\/template>/)
      end
    end

    context "with custom options" do
      subject {
        helper.input_add_button("Label", container_selector: "Container", class: "Class", id: "Id",
          data: {test: "test"}) { "Block" }
      }

      it 'should generate a button with correct attributes' do
        unsafe_html = CGI.unescapeHTML(subject)

        expect(unsafe_html).to match(/<div>/)
        expect(unsafe_html).to match(/<a.* class="Class".*>/)
        expect(unsafe_html).to match(/<a.* id="Id".*>/)
        expect(unsafe_html).to match(/<a.* data-test="test".*>/)
        expect(unsafe_html).to_not match(/<a.* data-form-input-target="addButton".*>/)
        expect(unsafe_html).to_not match(/<a.* data-add-dest-selector="Container".*>/)
        expect(unsafe_html).to_not match(/<a.* data-action="click->form-input#addItem:prevent".*>/)
        expect(unsafe_html).to match(/<a.*>Label<\/a>/)
        expect(unsafe_html).to match(/<template.* data-form-input-target="addTemplate".*>/)
        expect(unsafe_html).to match(/<template.*>Block<\/template>/)
      end
    end
  end

  describe 'input_delete_button' do
    context "with default options" do
      subject { helper.input_remove_button("Label", container_selector: "Container") }

      it 'should generate a button with correct attributes' do
        unsafe_html = CGI.unescapeHTML(subject)
        expect(unsafe_html).to match(/<a.* class="btn btn-warning".*>/)
        expect(unsafe_html).to match(/<a.* data-action="click->form-input#removeItem:prevent".*>/)
        expect(unsafe_html).to match(/<a.* data-remove-parent-selector="Container".*>/)
        expect(unsafe_html).to match(/<a.* data-remove-soft="false".*>/)
        expect(unsafe_html).to match(/<a.* href="javascript:void\(0\)".*>/)
        expect(unsafe_html).to match(/<a.*>Label<\/a>/)
      end

      context 'when soft is false' do
        subject { helper.input_remove_button("Label", container_selector: "Container", soft: true) }

        it 'should generate a button with correct attributes' do
          unsafe_html = CGI.unescapeHTML(subject)
          expect(unsafe_html).to match(/<a.* data-remove-soft="true".*>/)
        end
      end
    end

    context "with custom options" do
      subject { helper.input_remove_button("Label", container_selector: "Container", class: "test", data: {test: "test"}) }

      it 'should generate a button with correct attributes' do
        unsafe_html = CGI.unescapeHTML(subject)
        expect(unsafe_html).to match(/<a.* class="test".*>/)
        expect(unsafe_html).to_not match(/<a.* data-action="click->form-input#removeItem:prevent".*>/)
        expect(unsafe_html).to_not match(/<a.* data-remove-parent-selector="Container".*>/)
        expect(unsafe_html).to_not match(/<a.* data-remove-soft="true".*>/)
        expect(unsafe_html).to match(/<a.* data-test="test".*>/)
        expect(unsafe_html).to match(/<a.* href="javascript:void\(0\)".*>/)
        expect(unsafe_html).to match(/<a.*>Label<\/a>/)
      end
    end
  end
end

