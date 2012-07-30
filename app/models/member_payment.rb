class MemberPayment < ActiveRecord::Base
  belongs_to :weekly_task
  has_one :backlog_payment 
  # there is no belongs_to :transaction_activity
  # because 1 transaction activity can have 1 member payment, or many.. 
  # remember, the member can make multiple payment 
  
  # belongs_to :transaction_activity
  
  def transaction_activity
    TransactionActivity.find_by_id self.transaction_activity_id
  end
    #  
    # t.boolean  "has_paid",                :default => false
    #  t.boolean  "only_savings",            :default => false
    #  t.boolean  "no_payment",              :default => false
    #  
    #  
  def is_full_payment? 
    (only_savings == false ) && (no_payment == false ) && 
    (not transaction_activity_id.nil? )
  end
  
  def only_savings_payment?
    (has_paid == true ) && (only_savings == true ) && (no_payment == false ) && 
     (not transaction_activity_id.nil? )
  end
  
  def no_payment? 
    (has_paid == false ) && (only_savings == false ) && (no_payment == true ) &&  
     ( transaction_activity_id.nil? )
  end
  
  
  def MemberPayment.has_made_payment_for( weekly_task, week_number, member )
    # if it exists, can't be done.. has to be paid through backlog payment 
    MemberPayment.joins(:weekly_task).where(:week_number => week_number,
                        :member_id => member.id ,
                        :weekly_task => {:group_loan_id => weekly_task.group_loan_id}).length != 0 
  end
  
end
