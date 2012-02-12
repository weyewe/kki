class Group < ActiveRecord::Base
  has_many :group_memberships
  has_many :members, :though => :group_memberships
end
