class Member < ActiveRecord::Base
  has_many :groups, :through => :group_memberships
  has_many :group_memberships
  
  has_one :saving
  

  
end
