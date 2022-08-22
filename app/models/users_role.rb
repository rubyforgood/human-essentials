# from rolify
class UsersRole < ApplicationRecord
  belongs_to :user
  belongs_to :role

  accepts_nested_attributes_for :user
end
