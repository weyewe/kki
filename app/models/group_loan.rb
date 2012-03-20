=begin
  Group Loan Product, the domain of the branch manager
  Only branchmanager that can create a loan product 
=end
class GroupLoan < ActiveRecord::Base
  has_many :group_loan_memberships
  has_many :members, :through => :group_loan_memberships
  
  # belongs_to :group_loan 
  belongs_to :office
  validates_presence_of :name
  
  def get_commune
    commune = Commune.find_by_id self.commune_id
    village = commune.village
    subdistrict = village.subdistrict
    "#{subdistrict.name}, #{village.name} -- RW #{commune.number }"
  end
  
  def propose_to_start_group_loan
    
  end
  
  def start_loan
    ###### IMPORTANT ########## 
    # a member can only be in 1 group loan at a given time. 
    # so, when the loan is started, destroy all other group loan membership 
  end
  
  def commune
    Commune.find_by_id self.commune_id
  end
  
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
