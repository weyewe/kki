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
    # and group loan can't be started if there is a member with no group_loan_subcription 
    
    ## after the deposit  + initial savings has been received, loan $$$ can be disbursed 
  end
  
  def commune
    Commune.find_by_id self.commune_id
  end
  
  def all_group_loan_products_used
    group_loan_product_id_array = GroupLoanSubcription.
                select(:group_loan_product_id).
                where(:group_loan_membership_id => 
                      self.group_loan_membership_ids).map do |group_loan_subcription|
                        group_loan_subcription.group_loan_product_id
                      end
    
    group_loan_product_id_array.uniq.map do |group_loan_product_id|
      GroupLoanProduct.find_by_id group_loan_product_id
    end
  end
  
  def group_loan_membership_ids
    GroupLoanMembership.select(:id).find(:all, :conditions => {
      :group_loan_id => self.id
    }).map {|x| x.id }
  end
  
  def get_membership_for_member( member )
    GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => self.id,
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
