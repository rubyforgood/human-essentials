# == Schema Information
#
# Table name: banks
#
#  id                        :bigint           not null, primary key
#  address                   :string
#  email                     :string
#  name                      :string
#  opt_in_email_notification :boolean
#  phone                     :string
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
FactoryBot.define do
  factory :bank do
    
  end
end
