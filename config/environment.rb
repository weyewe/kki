# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Debita46::Application.initialize!

JAVA_ISLAND  = 1 
JAKARTA_PROVINCE = 1
NORTH_JAKARTA_REGENCY  = 1

CILINCING_SUBDISTRICT = 1


WEEKLY_PAYMENT_STATUS = {
  :unpaid => 0,
  # no $$ to pay, and no savings to cover for the payment
  :fail_payment => 1 ,
  
  :paid_recommended_value => 2,
  :paid_extra_savings => 3,
  :paid_late => 4,
  :paid_late_extra_savings => 5,
  :paid_multiple_weeks => 6,
  
  
  # if it is paid less than minimum, will be buffered (if total saving is less than the remnant)
  # if the total savings is more than the remnant due payment, will be autodeducted
  # "Backlog payment"
  
  :paid_less_than_minimum => 7 ,
  # using savings to pay for the minimum weekly payment
  :paid_total_minimum_from_savings => 8,
  # combining cash and savings
  :paid_partial_minimum_from_savings => 9
}



PAYMENT_TYPE = {
  # weekly payment for group loan 
  :weekly_principal => 1 , 
  :weekly_interest => 2 , 
  :weekly_saving => 3 ,
  :late_payment_fine => 4 , 
  
  # group loan creation
  :group_loan_admin_fee => 5,
  :group_loan_deposit => 6,
  :group_loan_initial_saving => 7 
  
}



TRUE_CHECK = 1
FALSE_CHECK = 0

PROPOSER_ROLE = 0 
APPROVER_ROLE = 1 

TRANSACTION_CASE = {
  :setup_payment => 1,
  :weekly_payment_basic => 2 , 
  :weekly_payment_no_principal => 3 , 
  :weekly_payment_extra_savings => 4 ,
  :weekly_payment_multiple_weeks => 5 , 
  :weekly_payment_soft_saving_withdrawal => 6,
  
  # all transaction from the company to the member
  :saving_withdrawal => 101, 
  :deposit_return_complete => 102, 
  :deposit_return_deduct_default => 103 
  
}

TRANSACTION_ENTRY_CODE = {
  :initial_deposit => 1,
  :initial_savings => 2, 
  :admin_fee => 3 ,
  :weekly_principal => 4,
  :weekly_saving => 5, 
  :weekly_interest => 6, 
  :late_payment_fine => 7 ,
  
  
  # all transaction from company to the member
  :return_deposit => 101, 
  :soft_savings_withdrawal => 102,
  :hard_saving_withdrawal => 103 
  
}




