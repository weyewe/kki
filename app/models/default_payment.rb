class DefaultPayment < ActiveRecord::Base
  belongs_to :group_loan_membership 
  

    
  attr_protected :amount_subgroup_share, :amount_group_share, :amount_paid, :is_grace_period_initialized
  
  def unpaid_grace_period_amount
    total_grace_period_amount - paid_grace_period_amount
  end
  
  def update_paid_grace_period_amount(amount)
    self.paid_grace_period_amount += amount
    self.save 
  end
  
  def is_actual_non_defaultee?
    self.is_defaultee == false or 
          (self.is_defaultee == true and    self.unpaid_grace_period_amount == BigDecimal('0'))
  end
  
  def cancel_update_paid_grace_period_amount(amount)
    self.paid_grace_period_amount -= amount
    self.save
  end
  
  
  def calculate_grace_period_amount
    glm = self.group_loan_membership
    glp  = glm.group_loan_product
    unpaid_backlogs_count = glm.unpaid_backlogs.count 
    self.total_grace_period_amount = unpaid_backlogs_count*glp.grace_period_weekly_payment
    self.save
  end
  
  
  def mark_as_defaultee
    self.is_grace_period_initialized = true 
    self.is_defaultee = true 
    self.save 
  end
  
  def mark_as_non_defaultee
    self.is_grace_period_initialized = true 
    self.is_defaultee = false 
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
  
  def DefaultPayment.rounding_up(amount,  nearest_amount ) 
    total = amount
    # total_amount

    multiplication_of_500 = ( total.to_i/nearest_amount.to_i ) .to_i
    remnant = (total.to_i%nearest_amount.to_i)
    if remnant > 0  
      return  nearest_amount *( multiplication_of_500 + 1 )
    else
      return nearest_amount *( multiplication_of_500  )
    end  
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
  
  
  def set_custom_amount( custom_amount ) 
    self.custom_amount = custom_amount
    self.save
  end
  
  def amount_to_be_paid
    
    # if self.custom_amount.nil? 
      return self.total_amount 
    # else
      # return self.custom_amount 
    # end
  end
  
  def set_default_amount_deducted(amount , transaction_activity  )
    
    # self.amount_paid = amount 
    self.is_paid = true 
    self.transaction_id = transaction_activity.id 
    self.save
  end
end
