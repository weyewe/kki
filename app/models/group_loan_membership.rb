class GroupLoanMembership < ActiveRecord::Base
  belongs_to :member
  belongs_to :group_loan
  
  belongs_to :sub_group 
  
  
  has_many :weekly_attendances
  has_many :weekly_payments 
  
  has_one :group_loan_subcription
  has_one :group_loan_product, :through => :group_loan_subcription
  
  # in the case of default payment (group loan)
  has_one :default_payment
  
  
  before_destroy :destroy_group_loan_subcription
  
  
  
  def add_deposit(field_worker, amount ) 
    # loan_product = self.group.group_loan 
    # "principal"
    # t.decimal  "interest"
    # t.decimal  "min_savings"
    # t.decimal  "admin_fee"
    # t.decimal  "initial_savings"
    self.initial_deposit = amount 
    self.initial_deposit_creator_id = field_worker.id
    self.paid_initial_deposit = true 
    self.save 
  end
  
  def add_initial_saving( field_worker, amount ) 
    loan_product = self.group.group_loan 
    if amount < loan_product.min_savings
      return false 
    else
      self.inital_saving = amount 
      self.initial_saving_creator_id = field_worker.id
      self.paid_initial_saving = true 
      # add the hook to update the Saving Book
      # create the payment hook here
      self.save 
    end
  end
  
  def add_admin_fee( field_worker, amount )
    loan_product = self.group.group_loan 
    if amount < loan_product.admin_fee
      return false 
    else
      self.paid_admin_fee = true 
      self.admin_fee_creator_id = field_worker.id
      # create the payment hook here
      self.save 
    end
  end
  
  
=begin
  Related with the group_loan_membership creation
=end
  def self.create_membership( creator, member, group_loan)
    
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => member.id,
      :group_loan_id => group_loan.id
    })
    
     # business logic , no new membership can be generated if the group loan is running 
    if group_loan.is_started == true
      return group_loan_membership  
    end
    
    
    
    if not group_loan_membership.nil?
      return group_loan_membership
    end
    
    
    # special for group_membership_creation
    # a new group membership can't be created if the member has ongoing active group_loan
    if member.current_active_group_loans != 0 
      return group_loan_membership
    end
    
    group_loan_membership = GroupLoanMembership.create(
      :member_id => member.id,
      :group_loan_id => group_loan.id
    )
    GroupLoanSubcription.create :group_loan_membership_id => group_loan_membership.id 
    # put the user activity list on who the creator is 
    return group_loan_membership
  end
  
  def self.destroy_membership( destroyer, member, group_loan)
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => member.id,
      :group_loan_id => group_loan.id
    })
    
    # business logic , no new membership can be generated if the group loan is running 
    if group_loan.is_started == true 
      return group_loan_membership
    end
    
    if  group_loan_membership.nil?
      return group_loan_membership
    end
    
    
    group_loan_membership.destroy 
    # put the user activity list on who the destroyer is 
  end
  
  
=begin
  Declaring that the setup payment will be deducted from Loan Disbursement 
=end

  def declare_setup_payment_by_loan_deduction
    self.deduct_setup_payment_from_loan = true
    self.save 
  end
  
  def min_setup_payment
    group_loan_product = self.group_loan_product
    group_loan_product.admin_fee + group_loan_product.initial_savings 
  end
  
  def has_paid_setup_payment?
    (self.has_paid_setup_fee == true) or
    (self.deduct_setup_payment_from_loan == true )
  end

  protected
  def destroy_group_loan_subcription
    GroupLoanSubcription.find(:all, :conditions => {
      :group_loan_membership_id => self.id
    }).each {|x| x.destroy }
  end
  
  
end
