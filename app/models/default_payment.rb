class DefaultPayment < ActiveRecord::Base
  belongs_to :group_loan_membership 
  

    
  attr_protected :amount_subgroup_share, :amount_group_share, :amount_paid
  
  def set_amount_group_share( amount ) 
    self.amount_group_share = amount
    self.save 
  end
  
  def set_amount_sub_group_share(amount)
    self.amount_sub_group_share  = amount
    self.save 
  end
  
  def set_default_payment_status_true
    self.is_defaultee = true 
    self.save
  end
  
end
