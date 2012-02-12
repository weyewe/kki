class GroupMembership < ActiveRecord::Base
  belongs_to :member
  belongs_to :group
  
  
  has_many :weekly_attendances
  has_many :weekly_payments 
end
