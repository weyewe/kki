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


