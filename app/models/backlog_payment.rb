=begin
  To record the weeks declared as no_payment
  and those declared as savings_only 
  
  # and the penalty payment as well
  
  #what happen when they cleared the backlog? 
  1. for the weekly_payment, the data will be altered. but the backlog will
    not be deleted. it is for analysis. 
  2. for penalty_payment, will just be created
=end

class BacklogPayment < ActiveRecord::Base
  belongs_to :group_loan
  belongs_to :weekly_task
  belongs_to :member_payment
  belongs_to :member
  
  def amount 
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => self.group_loan_id,
      :member_id => self.member_id
    })
    
    group_loan_membership.group_loan_product.total_weekly_payment
  end
  
  
  
  
  def BacklogPayment.list_member_id_with_default_in_group_loan( group_loan ) 
    BacklogPayment.find(:all, :conditions => {
      :group_loan_id => group_loan.id ,
      :is_cleared => false 
    }).collect {|x| x.member_id }.uniq
  end
end
