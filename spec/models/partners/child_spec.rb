# == Schema Information
#
# Table name: children
#
#  id                   :bigint           not null, primary key
#  active               :boolean          default(TRUE)
#  archived             :boolean
#  child_lives_with     :jsonb
#  comments             :text
#  date_of_birth        :date
#  first_name           :string
#  gender               :string
#  health_insurance     :jsonb
#  item_needed_diaperid :integer
#  last_name            :string
#  race                 :jsonb
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  agency_child_id      :string
#  family_id            :bigint
#
require "rails_helper"

RSpec.describe Partners::Child, type: :model, skip_seed: true do
  describe 'associations' do
    it { should belong_to(:family) }
    it { should have_many(:child_item_requests).dependent(:destroy) }
  end

  describe "#display_name" do
    subject { partners_child }
    let(:partners_child) { FactoryBot.create(:partners_child) }

    it "should return a child's first and last name" do
      expect(subject.display_name).to eq("#{subject.first_name} #{subject.last_name}")
    end
  end

  describe "#csv_headers" do
    subject { Partners::Child }
    let(:csv_headers) do
      %w[
        id first_name last_name date_of_birth gender child_lives_with race agency_child_id
        health_insurance comments created_at updated_at family_id item_needed_diaperid active archived
      ]
    end

    it "should have correct csv headers" do
      expect(subject.csv_headers).to eq(csv_headers)
    end
  end

  describe "#to_csv" do
    subject { partners_child }
    let(:partners_child) { FactoryBot.create(:partners_child) }
    let(:csv_array) do
      [
        subject.id,
        subject.first_name,
        subject.last_name,
        subject.date_of_birth,
        subject.gender,
        subject.child_lives_with,
        subject.race,
        subject.agency_child_id,
        subject.health_insurance,
        subject.comments,
        subject.created_at,
        subject.updated_at,
        subject.family_id,
        subject.item_needed_diaperid,
        subject.active,
        subject.archived
      ]
    end

    it "should return an array of values" do
      expect(subject.to_csv).to eq(csv_array)
    end
  end
end
