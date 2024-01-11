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
require 'rails_helper'

RSpec.describe Bank, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
