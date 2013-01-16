
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
SPECIAL_NOTICE_CHECK = -1 

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
  
  
  :default_payment_resolution_compulsory_savings_deduction_standard_amount => 80, 
  :default_payment_resolution_compulsory_savings_deduction_custom_amount => 81 ,
  
  
  # all transaction from the company to the member
  :loan_disbursement_no_setup_payment_deduction => 100,
  :loan_disbursement_with_setup_payment_deduction => 101,
  :cash_savings_withdrawal => 200, 
  :deposit_return_complete => 300, 
  :deposit_return_deduct_default => 301 ,
  
  :independent_savings_deposit => 500,
  
  :port_compulsory_savings_during_group_loan_closing => 600,
  :group_loan_savings_disbursement => 610, 
  :save_group_loan_disbursed_savings => 700,
  :add_savings_account => 701,  # deposit 
  :withdraw_savings_account => 702 ,  # withdrawal 
  :monthly_interest_savings_account => 703  # monthly interest, disbursed on 15th
  
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
  :grace_period_payment => 66, 
  :grace_period_payment_soft_savings_withdrawal => 67, 
  :grace_period_payment_extra_savings => 68, 
  
  
  :only_savings_independent_payment => 80, # during group loan.. member can only pay for independent payment  
  
  
  # all transaction from company to the member
  :return_deposit => 101, 
  :soft_savings_withdrawal => 200,
  :hard_saving_withdrawal => 201 ,
  :independent_savings_deposit => 250,  ##awesome, member starts  to save! #not independent payment.. has nothing to do with group loan 
  :loan_disbursement => 300,
  :total_loan_disbursement_amount => 301,
  :setup_fee_deduction_from_disbursement_amount => 310,
  
  
  # default_payment
  :default_loan_resolution_payment => 500,
  :extra_savings_from_default_loan_resolution_payment => 510,
  :default_payment_compulsory_savings_deduction => 511, 
  :default_payment_extra_savings_deduction => 512, 
  
  :default_loan_resolution_compulsory_savings_withdrawal => 600,
  
  :port_remaining_compulsory_savings_on_group_loan_close => 700,
  :group_loan_savings_disbursement => 710,
  
  # re-save the disbursed savings =>  
  :save_group_loan_disbursed_savings => 711,
  :add_savings_account => 712,
  :withdraw_savings_account => 713,
  :monthly_interest_savings_account => 714
  
}




SAVING_ENTRY_CODE = {
  :initial_setup_saving => 1 , 
  :weekly_saving_from_basic_payment => 2 , 
  :weekly_saving_extra_from_basic_payment => 3 ,
  :independent_savings_deposit => 4, 
  :no_weekly_payment_only_savings => 5 ,
  :only_savings_independent_payment => 70, 
  
  :soft_withdraw_to_pay_basic_weekly_payment => 100, 
  
  
  :soft_withdraw_to_pay_grace_payment => 150, 
  :extra_savings_from_grace_payment => 151, 
  
  
  :soft_withdraw_for_default_payment => 200,
  :weekly_saving_extra_from_default_payment => 250,
  
  :deduct_compulsory_savings_to_be_ported_to_extra_savings => 300,
  :add_extra_savings_from_compulsory_savings_deduction => 301 ,
  
  :deduct_compulsory_savings_for_default_payment => 401,
  :deduct_extra_savings_for_default_payment => 402,
  
  :deduct_extra_savings_for_cash_savings_withdrawal => 500,
  :group_loan_savings_disbursement =>   510,
  
  # the real savings account  => with monthly interest
  # we HOLD the transaction entry from 700 - 799 , special for those going in
  # and going out from SAVINGS_ACCOUNT
  :save_group_loan_disbursed_savings => 700 ,
  :add_savings_account => 701 ,
  :withdraw_savings_account => 702,
  :monthly_interest_savings_account => 703 
}
 
SAVING_CASE = {
  :group_loan => 1 ,
  :savings_account => 2 
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
  :personal_loan => 100,
  
  # naming this constant as LOAN_TYPE is wrong.. however, the show must go on
  #  the name TRANSACTION_ACTIVTY_TYPE fits better, nevertheless, not quite right 
  # OR PRODUCT_TYPE => can be savings_account(normal), periodic_savings, mission_savings,
  # personal_loan, and group_loan 
  :savings_account => 200
}


ATTENDANCE_STATUS = {
  :unmarked => 0 , 
  :present_on_time => 1 , 
  :present_late => 2 , 
  :absent => 3 ,
  :notice => 4 
}

DEFAULT_PAYMENT_ROUND_UP_VALUE = BigDecimal("500")

GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE = {
  :group_loan_lecture_absent => 0,
  :group_loan_disbursement_absent => 1,
  :group_loan_is_closed => 2 
}

# To monitor the group loan 
GROUP_LOAN_ASSIGNMENT= {
  :field_worker => 0 , 
  :loan_inspector  => 1 
}

# to clear the backlog
BACKLOG_CLEARANCE_PERIOD = {
  :in_weekly_payment_cycle => 1 , 
  :in_grace_period => 2 
}

BASIC_WEEKLY_PAYMENT_START = 77700000
BASIC_WEEKLY_PAYMENT_END = 77720000 # max = 777 11122

# cash, savings_withdrawal, extra_savings, number_of weeks, number_of_backlogs 
INDEPENDENT_PAYMENT_START = 88800000  
INDEPENDENT_PAYMENT_END = 888300000 # max+ 88811122
 
GRACE_PERIOD_PAYMENT_START = 666000  # cash , savings_withdrawal, extra_savings
GRACE_PERIOD_PAYMENT_END =   666200  # max= 666 1112 

SAVINGS_ACCOUNT_START = 700  # add savings account 
SAVINGS_ACCOUNT_END   = 750  # whatever 
MIN_SAVINGS_ACCOUNT_AMOUNT_DEPOSIT = BigDecimal("1000")
MIN_SAVINGS_ACCOUNT_AMOUNT_WITHDRAW = BigDecimal("100")

=begin
  MEMBER PAYMENT HISTORY 
=end

PAYMENT_PHASE = {
  :weekly_payment => 1, 
  :independent_payment => 2 , 
  :grace_payment => 3 
}


# 1 normal -> normal
#  2 only savings -> normal
#  3 no payment -> normal 
#  
#  4 normal -> only savings
#  5 only savings -> only savings
#  6 no payment -> only savings 
#  
#  7 normal -> no payment
#  8 only savings -> no payment
REVISION_CODE = {
  :normal => {
    :normal => 1,
    :only_savings => 4, 
    :no_payment => 7
  }, 
  :only_savings => {
    :normal => 2, 
    :only_savings => 5, 
    :no_payment => 8
  }, 
  :no_payment => {
    :normal => 3, 
    :only_savings => 6 
  } ,
  
  :original_normal => 11,
  :original_only_savings => 12,
  :original_no_payment => 13 ,
  
  :original_independent_only_savings => 30,
  :original_independent_normal => 31,
  
  :independent_normal => {
    :normal => 41,
    :only_savings => 42
  },
  
  :independent_only_savings => {
    :normal => 43, 
    :only_savings => 44 
  },
  
  :original_grace_payment => 70,
  :update_grace_payment => 71 
}

LOAN_PRODUCT = {
  :group_loan => 1 , 
  :personal_loan => 2 , 
  :savings_account  => 3 
}


LOCAL_TIME_ZONE = "Jakarta"
INTEREST_DAY_OF_THE_MONTH = 15 
# complete list, check here
# ActiveSupport::TimeZone.all.map(&:name)


=begin
  FOR MESSAGE BOX
=end
IMAGE_ASSET_URL = {
  # MSG BOX
  :alert => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/alert.png',
  :background => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/background.png',
  :confirm => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/confirm.png',
  :error => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/error.png',
  :info => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/info.png',
  :question => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/question.png',
  :success => 'http://s3.amazonaws.com/salmod/app_asset/msg-box/success.png'
}
