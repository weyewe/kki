class DefaultPayment < ActiveRecord::Base
  belongs_to :group_loan_membership 
  

    
  attr_protected :amount_subgroup_share, :amount_group_share, :amount_paid
  
  def mark_as_defaultee
    self.is_defaultee = true 
    self.save 
  end
  
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
        return  nearest_amount *( multiplication_of_500 + 1 )
      else
        return nearest_amount *( multiplication_of_500  )
      end  
    else
      return BigDecimal('0')
    end
  end
  
  
  def amount_to_be_paid
    
    if self.custom_amount.nil? 
      return self.total_amount 
    else
      return self.custom_amount 
    end
  end
  
  def set_default_amount_deducted(amount , transaction_activity  )
    
    self.amount_paid = amount 
    self.is_paid = true 
    self.transaction_id = transaction_activity.id 
    self.save
  end
end
