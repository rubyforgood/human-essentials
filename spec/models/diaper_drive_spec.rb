# == Schema Information
#
# Table name: diaper_drives
#
#  id         :bigint(8)        not null, primary key
#  name       :string
#  start_date :date
#  end_date   :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe DiaperDrive, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
