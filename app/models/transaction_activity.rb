=begin
  TransactionActivity is responsible to record the flow of $$$, from and to the member
  Flow from the member to company: in the form of 
    1. Payment
      - Setup Payment ( admin fee, deposit, initial savings )
      - Weekly Payment ( principal, interest, saving)
      - Fine for late weekly payment 
  
  Flow from the company to the member:
    1. Returning the deposit 
    2. Member withdraws $$ from savings
      - soft withdrawal (use the savings to pay for the loan)
      - hard withdrawal( take the cash )
  
=end

class TransactionActivity < ActiveRecord::Base
  has_many :transaction_entries 
  belongs_to :office 
  
  # has_one :member_payment
  
  
  # after_create :create_transaction_entries 
  
  
=begin
  On all payment
  1. check the value validity
  2. create the transaction activity 
  3. create the transaction entries associated with this transaction activity
  4. create the member savings ( if there is any ) 
  5. update the  group_loan_membership data
=end
  # all data coming in are BigDecimal
  def TransactionActivity.find_setup_transaction_for(group_loan_membership)
    member = group_loan_membership.member
    TransactionActivity.find(:first, :conditions => {
      :transaction_case => TRANSACTION_CASE[:setup_payment],
      :transaction_action_type => TRANSACTION_ACTION_TYPE[:inward],
      :member_id => member.id 
    })
  end
  
  def self.create_setup_payment( admin_fee, initial_savings, deposit, field_worker, group_loan_membership )
    group_loan_product = group_loan_membership.group_loan_subcription.group_loan_product
    
    # if there has been such payment
    if group_loan_membership.has_paid_setup_fee == true 
      return TransactionActivity.find_setup_transaction_for(group_loan_membership)
    end
    
    if initial_savings < group_loan_product.initial_savings  or 
            admin_fee < group_loan_product.admin_fee
      return nil
    end
    

    member = group_loan_membership.member 
    # group_loan = group_loan_membership.group_loan 
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = admin_fee +  initial_savings +  deposit
    new_hash[:transaction_case] = TRANSACTION_CASE[:setup_payment]
    new_hash[:creator_id] = field_worker.id 
    new_hash[:office_id] = field_worker.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_setup_entries( admin_fee, initial_savings, deposit, field_worker, member ) 
    # current_user.active_job_attachment.office
    
    
    group_loan_membership.deposit = deposit
    group_loan_membership.initial_savings = initial_savings
    group_loan_membership.admin_fee = admin_fee
    group_loan_membership.has_paid_setup_fee = true
    group_loan_membership.setup_fee_transaction_id = transaction_activity.id 
    group_loan_membership.save
    
    # member.add_savings(initial_savings, SAVING_ENTRY_CODE[:initial_setup_saving]) done in the transaction
    
    return transaction_activity 
    # group_loan.update_setup_deposit( group_loan_membership.deposit )
    # how can we create the transaction entries ?
  end
  
  
  def self.execute_loan_disbursement( group_loan_membership , cashier)
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member 
    
    new_hash = {}
    if group_loan_membership.deduct_setup_payment_from_loan ==true 
      #  create another transaction 
      new_hash[:total_transaction_amount]  = group_loan_product.loan_amount - group_loan_membership.min_setup_payment
      new_hash[:transaction_case] = TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]
      # new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:outward]
    else
      new_hash[:total_transaction_amount]  = group_loan_product.loan_amount
      new_hash[:transaction_case] = TRANSACTION_CASE[:loan_disbursement_no_setup_payment_deduction]
      # new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:outward]
    end


    # new_hash[:total_transaction_amount]  = group_loan_product.loan_amount
    # new_hash[:transaction_case] = TRANSACTION_CASE[:loan_disbursement]
    new_hash[:creator_id] = cashier.id 
    new_hash[:office_id] = cashier.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:outward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    transaction_activity = TransactionActivity.create new_hash 
    
    # this entries will be different, if the setup payment is paid using the loan 
    # deduct_setup_payment_from_loan = false 
    #   
    #   if group_loan_membership.deduct_setup_payment_from_loan ==true 
    #     deduct_setup_payment_from_loan = true
    #     transaction_activity.create_loan_disbursement_entries( group_loan_product.loan_amount , cashier, false ) 
    #   else
    #     transaction_activity.create_loan_disbursement_entries( group_loan_product.loan_amount , cashier, true ) 
    #   end
    
    transaction_activity.create_loan_disbursement_entries( group_loan_product.loan_amount , 
                      cashier, 
                      group_loan_membership.deduct_setup_payment_from_loan  ) 
    
    group_loan_membership.has_received_loan_disbursement = true
    group_loan_membership.loan_disbursement_transaction_id = transaction_activity.id 
    group_loan_membership.save 
    
   
    
    return transaction_activity 
  end
  

  def TransactionActivity.create_savings_only_weekly_payment(member,weekly_task, savings_amount,  current_user )
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    group_loan_product = group_loan_membership.group_loan_product
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = savings_amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:weekly_payment_only_savings]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]

    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_only_savings_payment_entry(savings_amount, current_user, member )

    weekly_task.create_weekly_payment_declared_as_only_savings( member, transaction_activity, savings_amount )

 
    return transaction_activity
  end
  
  def TransactionActivity.create_basic_weekly_payment(member,weekly_task, current_user )
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    group_loan_product = group_loan_membership.group_loan_product
    
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = group_loan_product.total_weekly_payment
    new_hash[:transaction_case] = TRANSACTION_CASE[:weekly_payment_basic]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_basic_payment_entries(group_loan_product, current_user, member )
    
    weekly_task.create_basic_weekly_payment( member, transaction_activity, group_loan_product.total_weekly_payment)
    
    # member.add_savings(group_loan_product.min_savings, 
    #          SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment])# done in the  create_basic_payment_entries
    
    return transaction_activity 
  end
  
  
  def TransactionActivity.create_structured_multiple_payment(member,weekly_task, current_user,
        cash, savings_withdrawal, number_of_weeks)
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    group_loan_product = group_loan_membership.group_loan_product
    basic_weekly_payment = group_loan_product.total_weekly_payment
    
    zero_value = BigDecimal.new("0")
    
    # check the validity, savings > savings withdrawal
    # balance >= 0 
    balance = cash + savings_withdrawal - ( basic_weekly_payment*number_of_weeks )
    total_savings = member.total_savings
    # if ( member.total_savings < savings_withdrawal ) or
    #       ( balance < zero_value )
    #     return nil
    #   end
    #   
    #   if( cash <= 0 ) && (balance <= zero_value) && (savings_withdrawal <= 0 )
    #     return nil
    #   end
    #   
    if ( not self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, number_of_weeks, basic_weekly_payment, total_savings ) ) and 
        (  number_of_weeks > ( group_loan_product.total_weeks - weekly_task.week_number + 1 )  )
      return false 
    end 
    
    new_hash = {}
    
  
    result_resolve = self.resolve_transaction_case(
      cash, 
      savings_withdrawal, 
      number_of_weeks,
      basic_weekly_payment,
      false # is_backlog_payment
    )
    
    if result_resolve.nil?
      puts "result resolve is nil\n"*10
      return nil
    end
    
    new_hash[:total_transaction_amount] = result_resolve[:total_transaction_amount]
    new_hash[:transaction_case]  = result_resolve[:transaction_case]
    
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_structured_multi_payment_entries(
              cash,
              savings_withdrawal,
              number_of_weeks, 
              group_loan_product,
              weekly_task ,
              current_user,
              member
            )
            
    if number_of_weeks == 1 
      weekly_task.create_basic_weekly_payment( member, transaction_activity, cash)
    elsif number_of_weeks > 1 
      weekly_task.create_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash)
    end
   
    
    return transaction_activity 
  end
  
  
  
  
=begin
  For backlog payments
=end

  def TransactionActivity.create_backlog_payments(member,group_loan, current_user,
        cash, savings_withdrawal, number_of_weeks)
   # defensive programming
   # 1. if the savings withdrawal is larger than savings, return nil 
   # 2. if the balance < 0  or  ( cash ==0 and savings_withdrawal == 0  ) , return nil 
   # 3. ? 
   
   
   
   group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
     :group_loan_id => group_loan.id, 
     :member_id => member.id 
   })
   group_loan_product = group_loan_membership.group_loan_product
   basic_weekly_payment = group_loan_product.total_weekly_payment
   total_savings = member.total_savings 
   # if (savings_withdrawal >)
   
   if (  not self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, 
                                    number_of_weeks, basic_weekly_payment, total_savings )  )and 
      ( number_of_weeks > member.total_backlog_payments_for_group_loan(group_loan))
     return false 
   end 
   
   new_hash = {}
   
 
   result_resolve = self.resolve_transaction_case(
     cash, 
     savings_withdrawal, 
     number_of_weeks,
     basic_weekly_payment,
     true # is_backlog_payment
   )
   
   
   if result_resolve.nil?
     puts "result resolve is nil\n"*10
     return nil
   end
   
   new_hash[:total_transaction_amount] = result_resolve[:total_transaction_amount]
   new_hash[:transaction_case]  = result_resolve[:transaction_case]
   
   new_hash[:creator_id] = current_user.id 
   new_hash[:office_id] = current_user.active_job_attachment.office.id
   new_hash[:member_id] = member.id
   
   transaction_activity = TransactionActivity.create new_hash 
   
   transaction_activity.create_backlog_payment_entries(
             cash,
             savings_withdrawal,
             number_of_weeks, 
             group_loan_product,
             current_user,
             member
           )
           
   # set the baclog payment to be cleared
   
  
   # if number_of_weeks == 1 
   #    weekly_task.create_basic_weekly_payment( member, transaction_activity, cash)
   #  elsif number_of_weeks > 1 
   #    weekly_task.create_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash)
   #  end
   # 
   
   member.backlog_payments_for_group_loan(group_loan).order("created_at ASC").limit( number_of_weeks ).each do |x|
     x.is_cleared  = true 
     x.backlog_cleared_declarator_id = current_user.id 
     x.save
   end
   
   return transaction_activity
        
        
  end

  
  
  
=begin
  Creating the transaction_entries associated with the transaction_activity 
=end

  def create_only_savings_payment_entry(savings_amount, current_user, member )
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings], 
                      :amount => savings_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_savings(savings_amount, SAVING_ENTRY_CODE[:no_weekly_payment_only_savings]) 

  end
  
  
  def create_setup_entries( admin_fee, initial_savings, deposit, field_worker , member) 
    cashflow_book = field_worker.active_job_attachment.office.cashflow_book
    # t.integer  "transaction_book_id"
    #    t.integer  "transaction_entry_code"
    #    t.decimal  "amount"
    #    t.integer  "cashflow_book_entry_id"
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:initial_deposit], 
                      :amount => deposit  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
    
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:initial_savings], 
                      :amount => initial_savings  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:admin_fee], 
                      :amount => admin_fee  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_savings(initial_savings, SAVING_ENTRY_CODE[:initial_setup_saving]) 
            
  end
  
  def create_loan_disbursement_entries( amount , cashier , deduct_setup_payment_from_loan ) 
    cashflow_book = cashier.active_job_attachment.office.cashflow_book
    
    if deduct_setup_payment_from_loan 
       deduction_amount = amount - self.total_transaction_amount
       self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:loan_disbursement], 
                          :amount => amount  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                          )
       self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:deduct_setup_fee_from_loan_disbursement], 
                          :amount => deduction_amount  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                          )
      
    else
      self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:loan_disbursement], 
                          :amount => amount  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                          )
    end
   
  end
  
  
  
  def create_basic_payment_entries(group_loan_product, field_worker , member)
    cashflow_book = field_worker.active_job_attachment.office.cashflow_book
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_principal], 
                      :amount => group_loan_product.principal  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
    
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_saving], 
                      :amount => group_loan_product.min_savings,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_interest], 
                      :amount => group_loan_product.interest,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_savings(group_loan_product.min_savings, SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment]) 
  end
  
  def create_extra_savings_entries( balance , current_user , member)
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_weekly_saving], 
                      :amount => balance ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_savings(balance, SAVING_ENTRY_CODE[:weekly_saving_extra_from_basic_payment]) 
  end
  
  def create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal], 
                      :amount => savings_withdrawal ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
                      
    # update member savings , add saving entries 
    member.deduct_savings( savings_withdrawal, SAVING_ENTRY_CODE[:soft_withdraw_to_pay_basic_weekly_payment])
    
  end
  
  def create_structured_multi_payment_entries(cash, savings_withdrawal, number_of_weeks, 
            group_loan_product, weekly_task , current_user , member)
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    balance = cash + savings_withdrawal- (group_loan_product.total_weekly_payment * number_of_weeks)
    
    if self.transaction_case == TRANSACTION_CASE[:weekly_payment_basic]
     self.create_basic_payment_entries(group_loan_product, current_user, member) 
     
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks]
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
     
    elsif self.transaction_case ==  TRANSACTION_CASE[:weekly_payment_single_week_extra_savings]
     self.create_basic_payment_entries(group_loan_product, current_user, member)
     self.create_extra_savings_entries( balance , current_user, member )
    
    elsif self.transaction_case ==  TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_extra_savings]
      self.create_extra_savings_entries( balance , current_user , member )
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      self.create_basic_payment_entries(group_loan_product, current_user, member ) 
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      self.create_basic_payment_entries(group_loan_product, current_user, member ) 
      self.create_extra_savings_entries( balance , current_user, member )
        
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal_extra_savings] 
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      self.create_extra_savings_entries( balance , current_user, member )
    
    end
  end
  
  def create_backlog_payment_entries( cash, savings_withdrawal,  number_of_weeks,  group_loan_product,
      current_user, member)
    # start 
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    balance = cash + savings_withdrawal- (group_loan_product.total_weekly_payment * number_of_weeks)
    
    if self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_exact_amount]
     self.create_basic_payment_entries(group_loan_product, current_user, member) 
     
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_exact_amount]
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
     
    elsif self.transaction_case ==  TRANSACTION_CASE[:single_backlog_payment_extra_savings]
     self.create_basic_payment_entries(group_loan_product, current_user, member)
     self.create_extra_savings_entries( balance , current_user, member )
    
    elsif self.transaction_case ==  TRANSACTION_CASE[:multiple_backlog_payment_extra_savings]
      self.create_extra_savings_entries( balance , current_user , member )
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      self.create_basic_payment_entries(group_loan_product, current_user, member ) 
      
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal_extra_savings]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      self.create_basic_payment_entries(group_loan_product, current_user, member ) 
      self.create_extra_savings_entries( balance , current_user, member )
        
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal_extra_savings] 
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, current_user, member) 
      end
      self.create_extra_savings_entries( balance , current_user, member )
    
    end
    
  end
  
  
=begin
  will return array of 
  { :transaction_amount, :transaction_case }
  Decoding the transaction_activity_code
=end
  def self.resolve_transaction_case( cash,  savings_withdrawal,  number_of_weeks, basic_weekly_payment, is_backlog_payment )
    total_fee  = number_of_weeks * basic_weekly_payment 
    balance = cash + savings_withdrawal -  total_fee
    transaction_amount = nil
    transaction_case = nil
    zero_value = BigDecimal.new("0")
   
 
    if (savings_withdrawal == zero_value) and (cash == total_fee ) and 
                  ( balance == zero_value )
                  
      transaction_amount   = cash 
      if number_of_weeks == 1 
        if is_backlog_payment == false 
          transaction_case  = TRANSACTION_CASE[:weekly_payment_basic]
        else
          transaction_case  = TRANSACTION_CASE[:single_backlog_payment_exact_amount]
        end
      else
        
        if is_backlog_payment == false 
          transaction_case  = TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks]
        else
          transaction_case  = TRANSACTION_CASE[:multiple_backlog_payment_exact_amount]
        end
        
      end
      
    elsif (savings_withdrawal ==  zero_value ) and (cash > total_fee ) and
                  (balance > zero_value)
                  
      transaction_amount = cash 
      
      if number_of_weeks == 1 
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_single_week_extra_savings]
        else
          transaction_case  = TRANSACTION_CASE[:single_backlog_payment_extra_savings]
        end
        
      else
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_extra_savings]
        else
          transaction_case  = TRANSACTION_CASE[:multiple_backlog_payment_extra_savings]
        end
        
      end
      
    elsif (savings_withdrawal > zero_value ) and ( balance == zero_value )
      #  (cash < total_fee ) and #independent of cash value 
                  
                  
      transaction_amount  = cash + savings_withdrawal
      
      if number_of_weeks == 1 
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal]
        else
          transaction_case  = TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal]
        end
        
        
      else
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal]
        else
          transaction_case  = TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal]
        end
        
      end
      
    elsif (savings_withdrawal > zero_value ) and  ( balance > zero_value )
      # (  or (cash < total_fee )  )and # doesn't depend on cash value
                 
                  
      transaction_amount  = cash + savings_withdrawal
      
      if number_of_weeks == 1 
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings]  
        else
          transaction_case  = TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal_extra_savings]
        end
        
      else
        if is_backlog_payment == false 
          transaction_case = TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal_extra_savings]  
        else
          transaction_case  = TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal_extra_savings]
        end
         
      end
      
    end
 
    
  
    if transaction_amount.nil? and transaction_case.nil?
      return nil
    else
      return  {
        :total_transaction_amount => transaction_amount , 
        :transaction_case  => transaction_case
      }
    end
  end
  
  def self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, number_of_weeks, basic_weekly_payment, total_savings )
    zero_value = BigDecimal.new("0")
    
    # check the validity, savings > savings withdrawal
    # balance >= 0 
    balance = cash + savings_withdrawal - ( basic_weekly_payment*number_of_weeks )
    
    if (  total_savings < savings_withdrawal )  or  # member can't withdraw more than what he has 
       (  cash <  zero_value )     or # negative cash? no such thing
       (  savings_withdrawal < zero_value )  or   # negative withdrawal? strange. Illogical
       (  balance < zero_value  )     or   # hey, how can the balance be negative? it means that the savings withdrawal and cash are not enough
       ( (balance == zero_value ) and ( cash == zero_value && savings_withdrawal == zero_value ))
       # balance can be zero: it means exact payment 
       # however, when balance is zero, either cash or savings withdrawal must be larger than zero 
      return false
    end
  
    
    return true 
    
    
  end
 
end
