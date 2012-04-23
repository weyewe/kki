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
end
