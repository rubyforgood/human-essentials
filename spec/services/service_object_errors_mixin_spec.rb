# frozen_string_literal: true

RSpec.describe ServiceObjectErrorsMixin do
  describe 'self.included' do
    before do
      stub_const 'TestClass', Class.new
    end

    it 'should add class methods to the class that include ServiceObjectErrorsMixin' do
      expect(TestClass.respond_to?(:human_attribute_name)).to be false
      TestClass.class_eval { include ServiceObjectErrorsMixin }
      expect(TestClass.respond_to?(:human_attribute_name)).to be true
    end
  end
end
