class Group < ActiveRecord::Base
  has_many :group_memberships
  has_many :members, :through => :group_memberships
  
  belongs_to :group_loan 
  
  def get_membership_for_member( member )
 
    GroupMembership.find(:first, :conditions => {
      :group_id => self.id,
      :member_id => member.id 
    })
  end
  
  def total_initial_admin_fee
  end
  
  def total_initial_deposit
  end
  
  def total_initial_saving
  end
  
end
