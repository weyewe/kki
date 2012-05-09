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
  
  def round_up_to( nearest_amount )
    total = amount_group_share + amount_sub_group_share
    # total_amount
    if self.is_defaultee == false 
      multiplication_of_500 = ( total.to_i/nearest_amount.to_i ) .to_i
      remnant = (total.to_i%nearest_amount.to_i)
      if remnant > 0  
        self.total_amount =  nearest_amount *( multiplication_of_500 + 1 )
        self.save
      end
    else
      return nil
    end
  end
  
  
  def set_default_amount_deducted(transaction_activity, member, any_amount_assumed_by_kki )
    if any_amount_assumed_by_kki == true 
      amount_assumed_by_kki = self.total_amount - member.total_savings 
      amount_paid = self.total_amount - amount_assumed_by_kki
      self.amount_paid = amount_paid
      self.is_paid = true 
      self.amount_assumed_by_office = amount_assumed_by_kki
      self.is_assumed_by_office = true 
  
    elsif any_amount_assumed_by_kki==false
      self.amount_paid = self.total_amount
      self.is_paid = true 
      
    end
    
    self.transaction_id = transaction_activity.id 
    self.save
  end
end
