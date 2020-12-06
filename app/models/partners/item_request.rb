# == Schema Information
#
# Table name: item_requests
#
#  id                 :bigint           not null, primary key
#  name               :string
#  partner_key        :string
#  quantity           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  item_id            :integer
#  partner_request_id :bigint
#
module Partners
  class ItemRequest < Base
    belongs_to :request, class_name: 'Partners::ItemRequest', foreign_key: :partner_request_id

    validates :quantity, presence: true
    validates :quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
    validates :name, presence: true
    validates :partner_key, presence: true
    has_many :child_item_requests, dependent: :destroy
    has_many :children, through: :child_item_requests
  end
end
