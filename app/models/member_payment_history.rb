class MemberPaymentHistory < ActiveRecord::Base
  
  belongs_to :member 
  # def MemberPaymentHistory.create_weekly_payment_history_entry(
  #   employee,  # creator 
  #   self,  # period object 
  #   self.group_loan,  # the loan product
  #   LOAN_PRODUCT[:group_loan],
  #   member, # the member who paid 
  #   BigDecimal('0'),  #  the cash passed
  #   BigDecimal('0'), # savings withdrawal used
  #   0, # in grace payment, number of weeks is nil 
  #   0, # in grace payment, number of weeks is nil 
  #   nil, # the transaction  
  #   REVISION_CODE[:original_no_payment],
  #   PAYMENT_PHASE[:weekly_payment] 
  # )
  validates_presence_of :member_id, :loan_product_id, :loan_product_type, :revision_code, :payment_phase
  
  
  
  
  def MemberPaymentHistory.edit_history_list_count(weekly_task, payment_phase, member )    
    total_count = MemberPaymentHistory.edit_history_list( weekly_task, payment_phase , member  ).count 
    
    return total_count - 1 
  end
  
  def MemberPaymentHistory.edit_history_list( weekly_task, payment_phase, member )     
    MemberPaymentHistory.where(
      :weekly_task_id => weekly_task.id ,
      :member_id =>  member.id, 
      :payment_phase =>payment_phase 
    )
  end
  
  
  
  def MemberPaymentHistory.create_weekly_payment_history_entry( employee, weekly_task, 
        loan_product, loan_product_type, member, 
        cash,
        savings_withdrawal,
        number_of_weeks,
        number_of_backlogs,
        transaction_id,
        revision_code,
        payment_phase) 
        
   
    
    MemberPaymentHistory.create(
      :weekly_task_id             => weekly_task.id , 
      :member_id                  => member.id ,
      :loan_product_id            => loan_product.id ,
      :loan_product_type          => loan_product_type,
      :cash                       => cash,
      :savings_withdrawal         => savings_withdrawal,
      :number_of_weeks            => number_of_weeks,
      :number_of_backlog => number_of_backlogs,
      :creator_id                 => employee.id ,
      :transaction_activity_id    => transaction_id,
      :revision_code              => revision_code,
      :payment_phase              => payment_phase
    )
    
  end
  
  
  def self.effective_weekly_payments(member_id_list, weekly_task) 
  end
end
