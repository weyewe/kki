class GroupLoanMembership < ActiveRecord::Base
  belongs_to :member
  belongs_to :group_loan
  
  
  has_many :weekly_attendances
  has_many :weekly_payments 
  
  has_one :loan_subcription
  has_one :group_loan_product, :through => :loan_subcription
  
  
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
end
