
JAVA_ISLAND  = 1 
JAKARTA_PROVINCE = 1
NORTH_JAKARTA_REGENCY  = 1

CILINCING_SUBDISTRICT = 1

puts "Gonna assign user role "
USER_ROLE = {
  :branch_manager => "BranchManager",
  :cashier => "Cashier",
  :loan_officer => "LoanOfficer",
  :field_worker => "FieldWorker"
}

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

DEV_EMAIL = "w.yunnal@gmail.com"

TRUE_CHECK = 1
FALSE_CHECK = 0

PROPOSER_ROLE = 0 
APPROVER_ROLE = 1 

TRANSACTION_CASE = {
  :setup_payment => 1,
  :weekly_payment_basic => 2 , 
  :weekly_payment_only_savings => 3 , 
  # case: basic payment is 32k. member gave 40k. Use the change as savings
  :weekly_payment_single_week_extra_savings => 4 ,
  
  # case: basic_payment is 32k. member has only 20k cash. 
  #   but, his savings is more than the delta. so, he can pay in cash 20k, and 12k from savings
  :weekly_payment_single_week_structured_with_soft_savings_withdrawal => 5 , 
  # case 6 should never happen.
  # if basic payment is 32k. member has only 20k. His savings is more than 12k. 
  # He shouldn't withdraw 14 k, and using 18k cash + 2k savings 
  # but, most of the users are stupid. so, fuck it. s
  :weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings => 6 ,
  
  
  :weekly_payment_structured_multiple_weeks => 7 , 
  :weekly_payment_structured_multiple_weeks_extra_savings => 8 , 
  :weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal => 9,
  :weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal_extra_savings => 10,
  
  
  # backlog payment 
  :single_backlog_payment_exact_amount => 51, # has to be paid in full
  :single_backlog_payment_extra_savings => 52,
  :single_backlog_payment_soft_savings_withdrawal => 53, 
  :single_backlog_payment_soft_savings_withdrawal_extra_savings => 54, 
  
  :multiple_backlog_payment_exact_amount => 55,
  :multiple_backlog_payment_extra_savings => 56,
  :multiple_backlog_payment_soft_savings_withdrawal => 57, 
  :multiple_backlog_payment_soft_savings_withdrawal_extra_savings => 58, 
  
  
  
  
  :default_payment_automatic_deduction => 80, 
  # :default_loan_payment_as_sub_group_member => 70,
  # :default_loan_payment_as_group_member => 71, 
  
  # 4 cases for default payment , old scheme where member can deduct on their own
  # chose:cash, savings withdrawal etc 
  :default_payment_resolution_only_cash => 70,
  :default_payment_resolution_only_savings_withdrawal => 71,
  
  :default_payment_resolution_only_cash_extra_savings => 72,
  :default_payment_resolution_only_savings_withdrawal_extra_savings => 73,
  
  :default_payment_resolution_cash_and_savings_withdrawal => 74,
  :default_payment_resolution_cash_and_savings_withdrawal_extra_savings => 75,
  
  # all transaction from the company to the member
  :loan_disbursement_no_setup_payment_deduction => 100,
  :loan_disbursement_with_setup_payment_deduction => 101,
  :saving_withdrawal => 200, 
  :deposit_return_complete => 300, 
  :deposit_return_deduct_default => 301 ,
  
  :independent_savings_deposit => 500
  
}

TRANSACTION_ENTRY_CODE = {
  :initial_deposit => 1,
  :initial_savings => 2, 
  :admin_fee => 3 ,
  :weekly_principal => 4,
  :weekly_saving => 5, 
  :weekly_interest => 6, 
  :late_payment_fine => 7 ,
  :extra_weekly_saving => 8, 
  :no_weekly_payment_only_savings => 9,
  
  # all transaction from company to the member
  :return_deposit => 101, 
  :soft_savings_withdrawal => 200,
  :hard_saving_withdrawal => 201 ,
  :independent_savings_deposit => 250,  ## awesome, member starts  to save!
  :loan_disbursement => 300,
  :total_loan_disbursement_amount => 301,
  :setup_fee_deduction_from_disbursement_amount => 310,
  
  
  # default_payment
  :default_loan_resolution_payment => 500,
  :extra_savings_from_default_loan_resolution_payment => 510
  
}




SAVING_ENTRY_CODE = {
  :initial_setup_saving => 1 , 
  :weekly_saving_from_basic_payment => 2 , 
  :weekly_saving_extra_from_basic_payment => 3 ,
  :independent_savings_deposit => 4, 
  :no_weekly_payment_only_savings => 5 ,
  
  :soft_withdraw_to_pay_basic_weekly_payment => 100, 
  :hard_withdrawal => 101,
  
  :soft_withdraw_for_default_payment => 200,
  :weekly_saving_extra_from_default_payment => 250
  
 
  
}

SAVING_ACTION_TYPE = {
  :debit => 1 , # money is going into the member's savings account
  :credit => 2  # money is going out from the member's savings account
}

TRANSACTION_ACTION_TYPE = {
  :inward => 1 , #money is going into the company
  :outward => 2  # money is going out from the company
}


TRANSACTION_ENTRY_ACTION_TYPE = {
  :inward => 1 , #money is going into the company
  :outward => 2  # money is going out from the company
}

BACKLOG_TYPE = {
  :only_savings_without_weekly_payment => 1,
  :no_payment =>2 
}


LOAN_TYPE = {
  :group_loan => 1 ,
  :personal_loan => 100
}


ATTENDANCE_STATUS = {
  :unmarked => 0 , 
  :present_on_time => 1 , 
  :present_late => 2 , 
  :absent => 3 
}

DEFAULT_PAYMENT_ROUND_UP_VALUE = BigDecimal("500")

GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE = {
  :group_loan_lecture_absent => 0,
  :group_loan_disbursement_absent => 0 
}

# To monitor the group loan 
GROUP_LOAN_ASSIGNMENT= {
  :field_worker => 0 , 
  :loan_inspector  => 1 
}