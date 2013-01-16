class MemberPayment < ActiveRecord::Base
  belongs_to :weekly_task
  has_one :backlog_payment 
  belongs_to :member 
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
    (not transaction_activity_id.nil? ) && 
     (week_number != nil)   # independent payment: can be full payment.
  end
  
  def is_backlog_full_payment?
    (only_savings == false ) && (no_payment == false ) &&  (only_extra_savings == false ) && 
    (not transaction_activity_id.nil? )
    
  end
  
  def only_savings_independent_payment? 
     (has_paid == true ) && (only_extra_savings == true ) && 
     (week_number == nil) && (is_independent_weekly_payment == true )
  end
  
  # def is_backlog_payment?
  #   self.member_payments.create(
  #     :transaction_activity_id => transaction_activity.id,
  #     :member_id => member.id , 
  #     :cash_passed => cash_passed,
  #     :week_number => nil ,
  #     :is_independent_weekly_payment => is_independent_payment
  #   )
  # end
  # 
  def only_savings_payment?
    (has_paid == true ) && (only_savings == true ) && (no_payment == false ) && 
     (not transaction_activity_id.nil? ) && 
      (week_number != nil) && (is_independent_weekly_payment == false ) # the true case is handled by only_savings_independent_payment?
  end
  
  def no_payment? 
    (has_paid == false ) && (only_savings == false ) && (no_payment == true ) &&  
     ( transaction_activity_id.nil? ) && 
      (week_number != nil) && (is_independent_weekly_payment == false )
  end
  
  
  
  
  def payment_in_the_previous_week(weekly_task  ) 
     
    MemberPayment.where{
      ( transaction_activity_id.not_eq nil ) & 
      ( has_paid.eq false ) & 
      ( week_number.eq weekly_task.week_number ) & 
      ( member_id.eq self.member_id ) & 
      (weekly_task_id.eq weekly_task.id)
    }.first 
  end
  
  # to check whether there is any payment 
  def MemberPayment.has_made_payment_for( weekly_task, week_number, member )
    # if it exists, can't be done.. has to be paid through backlog payment 
    MemberPayment.joins(:weekly_task).where(:week_number => week_number,
                        :member_id => member.id ,
                        :weekly_task => {:group_loan_id => weekly_task.group_loan_id}).length != 0 
  end
  
  
=begin
  Only one dangling independent payment allowed 
=end

# hooked to the weekly task 
  def MemberPayment.any_independent_payment_pending_approval?(member)
    transaction_activity_id_list = MemberPayment.where( 
       :member_id => member.id , 
       :has_paid => true , 
       :week_number =>nil,
       :is_independent_weekly_payment => true 
     ).map {|x| x.transaction_activity_id}
     
     TransactionActivity.where(:id =>transaction_activity_id_list, 
          :is_approved => false, 
          :is_deleted => false, 
          :is_canceled => false   ).count != 0 
  end
  
 
  
end
