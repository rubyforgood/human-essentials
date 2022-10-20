# == Schema Information
#
# Table name: counties
#
#  id         :bigint           not null, primary key
#  name       :string
#  region     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class County < ApplicationRecord
end
