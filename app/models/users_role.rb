# from rolify
class UsersRole < ApplicationRecord
  belongs_to :user
  belongs_to :role
end
