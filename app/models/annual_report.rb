# == Schema Information
#
# Table name: annual_reports
#
#  id              :bigint           not null, primary key
#  all_reports     :json
#  year            :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  organization_id :bigint
#
class AnnualReport < ApplicationRecord
  has_paper_trail
  belongs_to :organization, inverse_of: :annual_reports
  validates :year, numericality: { greater_than: 1900, less_than: 10_000 }

  # @yield [String, Array<Hash>]
  def each_report
    all_reports.each { |hash| yield hash['name'], hash['entries'] }
  end
end
