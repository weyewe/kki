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
  
  attr_protected :is_proposed, :group_loan_proposer_id,
                  :is_started, :group_loan_starter_id ,
                  :is_closed, :group_loan_closer_id, 
                  :is_setup_fee_collection_approved, :setup_fee_collection_approver_id,
                  :aggregated_principal_amount, :aggregated_interest_amount,
                  :total_default, :default_creator_id 
                  
  
  # :is_started, :is_closed, :is_proposed, 
  #                   :aggregated_principal_amount, 
  #                   :aggregated_interest_amount,
  #                   :total_default
  # 
  # t.string   "name"
  # t.integer  "creator_id",                            :null => false
  # t.integer  "office_id"
  # t.boolean  "is_closed",          :default => false
  # t.integer  "group_closer_id"
  # t.boolean  "is_started",         :default => false
  # t.integer  "group_starter_id"
  # t.integer  "total_default"
  # t.boolean  "any_default",        :default => false
  # t.integer  "default_creator_id"
  # t.integer  "commune_id"
  # t.datetime "created_at"
  # t.datetime "updated_at"
  
  
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
  
  def unassigned_members
    # get the group_loan_membership where group_loan_subcription is nil
    # Client.joins(:orders).where(:orders => {:created_at => time_range})
    GroupLoanMembership.joins(:group_loan_subcription).where(
      :group_loan_subcription => {:group_loan_product_id => nil}
    )
    
  end
  
  def change_group_loan_subcription( new_group_loan_product_id , old_group_loan_product_id)
    new_group_loan_product = GroupLoanProduct.find_by_id  new_group_loan_product_id
    old_group_loan_product = GroupLoanProduct.find_by_id old_group_loan_product_id
    
    delta_principal = new_group_loan_product.loan_amount  - old_group_loan_product.loan_amount
    delta_interest = new_group_loan_product.interest_amount  - old_group_loan_product.interest_amount
  
    update_aggregated_interest_amount( delta_interest )
    update_aggregated_principal_amount( delta_principal )
  end
  
  def add_group_loan_subcription( group_loan_product_id )
    group_loan_product = GroupLoanProduct.find_by_id  group_loan_product_id
    
    update_aggregated_interest_amount( group_loan_product.interest_amount )
    update_aggregated_principal_amount( group_loan_product.loan_amount )
  end
  
  def update_aggregated_interest_amount( delta_interest) 
    self.aggregated_interest_amount += delta_interest
    self.save
  end
  
  def update_aggregated_principal_amount( delta_principal) 
    self.aggregated_principal_amount += delta_principal
    self.save
  end
  
  def aggregated_interest_rate
    self.aggregated_interest_amount/self.aggregated_principal_amount
  end
  
  def aggregated_interest_rate_percentage
    (self.aggregated_interest_amount/self.aggregated_principal_amount).to_f * 100
  end
  
=begin
  Finalization Approval 
=end

  def execute_propose_finalization( current_user )
    self.is_proposed = true 
    self.group_loan_proposer_id = current_user.id 
    self.save 
  end
end
