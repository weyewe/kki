=begin
  TransactionActivity is responsible to record the flow of $$$, from and to the member
  total amount represents the HARD CASH, moving from employee to member, vice versa
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
  # has_many :saving_entries
  
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
  
  def TransactionActivity.create_independent_savings( member, amount, field_worker )
    
    # member.add_savings()
    if amount <= BigDecimal("0")
      return nil
    end
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:independent_savings_deposit]
    new_hash[:creator_id] = field_worker.id 
    new_hash[:office_id] = field_worker.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    # new_hash[:loan_type] = 
    #    new_hash[:loan_id] = 
    
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_independent_savings_entry( amount, field_worker, member )
    
    
    return transaction_activity
    
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
  
  
  def self.execute_loan_disbursement( group_loan_membership , employee)
    # can only be executed by cashier  # wrong. latest update -> By field worker.
    # cashier passed the $$$ to the field worker. 
    # field worker give it to the member. pass the remaining to the cashier
    # if there is member absent during the disbursement 
    if not employee.has_role?(:field_worker, employee.get_active_job_attachment)
      return nil
    end
    
  
   if group_loan_membership.is_active == false
     return nil
   end
   
   if group_loan_membership.is_active == true && group_loan_membership.is_attending_loan_disbursement.nil?
     return nil
   end
    
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member
    
    initial_savings = group_loan_product.initial_savings
    
    # can't be executed if there is previous loan disbursement for the same entry
    
    # past_transaction_activity = TransactionActivity.previous_transaction_activity( weekly_task, member )
    #     if not past_transaction_activity.nil?
    #       return past_transaction_activity
    #     end
    
    
    old_payment =  TransactionActivity.find(:first, :conditions => {
      :member_id => member.id, 
      :loan_type => LOAN_TYPE[:group_loan],
      :loan_id => group_loan_membership.group_loan_id,
      :transaction_case => [
        TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction], 
        TRANSACTION_CASE[:loan_disbursement_no_setup_payment_deduction]
      ]
    })
    if not old_payment.nil?
      return old_payment
    end

    new_hash = {}
    if group_loan_membership.deduct_setup_payment_from_loan == true 
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
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:outward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    transaction_activity = TransactionActivity.create new_hash 
    
    
    transaction_activity.create_loan_disbursement_entries( group_loan_product.loan_amount , 
                      group_loan_product.admin_fee, 
                      group_loan_product.initial_savings,
                      employee, 
                      group_loan_membership.deduct_setup_payment_from_loan , member ) 
    
    group_loan_membership.has_received_loan_disbursement = true
    group_loan_membership.loan_disbursement_transaction_id = transaction_activity.id 
    group_loan_membership.save 
    
   
    
    return transaction_activity 
  end
  
  def TransactionActivity.previous_transaction_activity( weekly_task, member )
    member_payment = weekly_task.member_payment_for(member)
    if ( not member_payment.nil? )  and (not member_payment.transaction_activity.nil?)
      return member_payment.transaction_activity
    end
  end
  
  def TransactionActivity.create_savings_only_weekly_payment(member,weekly_task, savings_amount,  current_user )
    if not TransactionActivity.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, current_user )
      return nil
    end
    
    if savings_amount <= BigDecimal("0")
      return nil
    end
    
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    group_loan_product = group_loan_membership.group_loan_product
    
    # wrong, fucking wrong
    
    past_transaction_activity = TransactionActivity.previous_transaction_activity( weekly_task, member )
    if not past_transaction_activity.nil?
      return past_transaction_activity
    end
    
    
    
  
    
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = savings_amount
    new_hash[:transaction_case] = TRANSACTION_CASE[:weekly_payment_only_savings]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id

    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_only_savings_payment_entry(savings_amount, current_user, member )

    weekly_task.create_weekly_payment_declared_as_only_savings( member, transaction_activity, savings_amount )

 
    return transaction_activity
  end
  
  def TransactionActivity.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, current_user )
    if  (not current_user.has_role?(:field_worker, current_user.get_active_job_attachment) ) or
        ( not weekly_task.is_weekly_attendance_marking_done == true )
        return false
    else
      return true
    end
  end
  
  
  
  def TransactionActivity.create_generic_weekly_payment(
          group_loan_membership,
          employee,
          cash,
          savings_withdrawal, 
          number_of_weeks,
          number_of_backlogs)
          
    group_loan = group_loan_membership.group_loan
    
    if not ( group_loan.is_loan_disbursement_done?  )  # && Excess money is returned to the cashier
      return nil 
    end
    
  end 
  
  
  def TransactionActivity.create_basic_weekly_payment(member,weekly_task, current_user )
    if not self.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, current_user )
      return nil
    end
    
  
    
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    group_loan_product = group_loan_membership.group_loan_product
    
    
    past_transaction_activity = TransactionActivity.previous_transaction_activity( weekly_task, member )
    if not past_transaction_activity.nil?
      return past_transaction_activity
    end
    
    # old_payment =  TransactionActivity.find(:first, :conditions => {
    #       :member_id => member.id, 
    #       :loan_type => LOAN_TYPE[:group_loan],
    #       :loan_id => group_loan_membership.group_loan_id,
    #       :transaction_case =>   TRANSACTION_CASE[:weekly_payment_basic]
    #     })
    #     if not old_payment.nil?
    #       return old_payment
    #     end
   
    
    
    
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = group_loan_product.total_weekly_payment
    new_hash[:transaction_case] = TRANSACTION_CASE[:weekly_payment_basic]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_basic_payment_entries(group_loan_product, current_user, member )
    
    weekly_task.create_basic_weekly_payment( member, transaction_activity, group_loan_product.total_weekly_payment)
    
    # member.add_savings(group_loan_product.min_savings, 
    #          SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment])# done in the  create_basic_payment_entries
    
    return transaction_activity 
  end
  
  def TransactionActivity.is_number_of_weeks_valid?(number_of_weeks, group_loan, weekly_task, member)
    #this one look wrong.. potential for double payment 
    # ( group_loan.remaining_weekly_tasks_count_for_member(member) <= number_of_weeks )  and 
    # ( number_of_weeks > 0   ) # and
     #    ( number_of_weeks > ( group_loan.total_weeks - weekly_task.week_number+   1) ) # and 
    #     ( not weekly_task.has_paid_weekly_payment?(member) )
    # true
    
    if ( number_of_weeks > group_loan.total_weeks ) or
      ( number_of_weeks <= 0 ) or 
      #(  weekly_task.has_paid_weekly_payment?(member) ) or  # doesn't matter. the payment won't be counted towards this weekly task
      ( number_of_weeks > group_loan.remaining_weekly_tasks_count_for_member(member) ) or 
      (group_loan.remaining_weekly_tasks_count_for_member(member) == 0 )
      return false
    else
      return true
    end
  end
  
  def TransactionActivity.is_number_of_weeks_valid_for_backlog_payment?(number_of_weeks, group_loan, member)
    #this one look wrong.. potential for double payment 
    # ( group_loan.remaining_weekly_tasks_count_for_member(member) <= number_of_weeks )  and 
    # ( number_of_weeks > 0   ) # and
     #    ( number_of_weeks > ( group_loan.total_weeks - weekly_task.week_number+   1) ) # and 
    #     ( not weekly_task.has_paid_weekly_payment?(member) )
    # true
    
    if ( number_of_weeks > group_loan.unpaid_backlogs.count ) or
      ( number_of_weeks <= 0 ) 
      return false
    else
      return true
    end
  end
    # 
    # 
    # def TransactionActivity.is_number_of_weeks_for_structured_multiple_payment_valid?( group_loan, member, number_of_weeks )
    #   if ( group_loan.remaining_weekly_tasks_count_for_member(member) ) <= 0  or 
    #     (number_of_weeks > group_loan.remaining_weekly_tasks_count_for_member(member)  ) or
    #     ( number_of_weeks == 0 )
    #     return false # no transaction can be done.. even if it is multiple weeks 
    #     # if you wish, do the backlog payment. When is declared as no payment, it is no payment
    #   else
    #     return true
    #   end
    # end
  
  def TransactionActivity.create_structured_multiple_payment(member,weekly_task, current_user,
        cash, savings_withdrawal, number_of_weeks)
        
    if not self.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, current_user )
      return nil
    end
    group_loan = weekly_task.group_loan
    group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :group_loan_id => group_loan.id, 
      :member_id => member.id 
    })
    
    # group_loan_membership.extract_remaining_weeks
    
    # if weekly_task !=  group_loan.currently_being_payment_collected_weekly_task
    #       return nil
    #     end
    # no such limitation. 
  
        # 
        # if not TransactionActivity.is_number_of_weeks_valid?(number_of_weeks, group_loan, weekly_task, member)
        #   return nil
        # end
    
    
    group_loan_product = group_loan_membership.group_loan_product
    basic_weekly_payment = group_loan_product.total_weekly_payment
    
    zero_value = BigDecimal.new("0")
    
    # check the validity, savings > savings withdrawal
    # balance >= 0 
    balance = cash + savings_withdrawal - ( basic_weekly_payment*number_of_weeks )
    total_extra_savings = member.total_extra_savings
    
    # if( member.total_savings < savings_withdrawal)
    #       return nil
    #     end
    
    if ( not self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, number_of_weeks, basic_weekly_payment, total_extra_savings ) ) or 
        not TransactionActivity.is_number_of_weeks_valid?(number_of_weeks, group_loan, weekly_task, member)
       
      return nil 
    end 
    
    # if all_weekly_task_has_been_paid?
    #      return nil
    #    end
    
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
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
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
    
    #  the last problem.. it has to be sequential, week number 1 -> x 
    # no double s
    # adjusting the weekly task 
    
    if weekly_task.has_paid_weekly_payment?(member)  
      weekly_task = WeeklyTask.first_unpaid_weekly_task(group_loan, member)
      if weekly_task.nil? 
        return nil
      end
    end
    
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
   
   if savings_withdrawal > member.total_savings
     return nil
   end
   
   
   group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
     :group_loan_id => group_loan.id, 
     :member_id => member.id 
   })
   group_loan_product = group_loan_membership.group_loan_product
   basic_weekly_payment = group_loan_product.total_weekly_payment
   total_extra_savings = member.total_extra_savings 
   # if (savings_withdrawal >)
   
   if (  not self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, 
                                    number_of_weeks, basic_weekly_payment, total_extra_savings )  )and 
      TransactionActivity.is_number_of_weeks_valid_for_backlog_payment?(number_of_weeks, group_loan, member)
      
      
     return nil 
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
   new_hash[:loan_type] = LOAN_TYPE[:group_loan]
   new_hash[:loan_id] = group_loan_membership.group_loan_id
   
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
     x.transaction_activity_id_for_backlog_clearance = transaction_activity.id
     x.save
   end
   
   return transaction_activity
        
        
  end
  
  
  def TransactionActivity.extract_transaction_pending_backlogs_pair(group_loan)
    pending_backlogs_transaction_id_list = group_loan.pending_approval_backlogs.
                                                    map{|x| x.transaction_activity_id_for_backlog_clearance }.uniq
                                                    
    pair = []
    pending_backlogs_transaction_id_list.each do |transaction_activity_id|
      transaction_activity = TransactionActivity.find_by_id transaction_activity_id
      # backlog_payments = BacklogPayment.find(:all, :conditions => {
      #       :transaction_activity_id_for_backlog_clearance => transaction_activity.id 
      #     }) 
      backlog_payments = transaction_activity.backlog_payments
      member = backlog_payments.first.member 
      pair << {
        :cash_exchanging_hands_amount => transaction_activity.total_transaction_amount,
        :field_worker_id => transaction_activity.creator_id, 
        :backlog_payments => backlog_payments,
        :member => member,
        :savings_withdrawal => transaction_activity.savings_withdrawal_amount,
        :transaction_activity_id =>transaction_activity_id,
        :number_of_weeks_paid => backlog_payments.count
      }
    end
    
    return pair
  end
  
  def backlog_payments
    BacklogPayment.find(:all, :conditions => {
      :transaction_activity_id_for_backlog_clearance => self.id 
    })
  end
  
  def approve_backlog_payments(current_user)
    if  not current_user.has_role?(:cashier, current_user.get_active_job_attachment)
      return nil
    end
    
    self.backlog_payments.each do |backlog_payment|
      backlog_payment.create_cashier_cash_approval(current_user)
    end
    
    
  end
  
  def savings_withdrawal_amount
    savings_withdrawal_entry = self.transaction_entries.
                            where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal])
    if savings_withdrawal_entry.length != 0 
      return savings_withdrawal_entry.first.amount
    else
      return BigDecimal("0")
    end
  end
  
  
  
=begin
  For the default loan resolution
=end

  def TransactionActivity.execute_default_payment_deduction_from_savings(group_loan,default_payment,glm, current_user)
    member = glm.member
    
    
    new_hash = {}
    new_hash[:total_transaction_amount] = BigDecimal("0") #no hard money flowing 
    new_hash[:transaction_case]  = TRANSACTION_CASE[:default_payment_automatic_deduction]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = glm.group_loan_id

    transaction_activity = TransactionActivity.create new_hash
    
    
    if default_payment.total_amount > member.total_savings
      default_payment.set_default_amount_deducted(transaction_activity, member, true)
    else
      default_payment.set_default_amount_deducted(transaction_activity, member, false)
    end
    
    # member.deduct_savings( default_payment.amount_paid, SAVING_ENTRY_CODE[:soft_withdraw_for_default_payment] , transaction_entry )
    # the savings deduction is done in the transaction entry
    # transaction_activity.create_auto_default_payment_resolution_entries( default_payment) 
    transaction_activity.create_default_payment_savings_withdrawal_transaction_entry(default_payment.amount_paid , member)
    return transaction_activity
  end
  
  
  # the old scheme where member can choose to pay by cash
  #the new scheme: deduct automatically from savings. The excess is covered by KKI
  def TransactionActivity.create_default_loan_resolution_payment(   default_payment,
                                                        current_user,
                                                        cash, 
                                                        savings_withdrawal)
    group_loan_membership = default_payment.group_loan_membership
    member = group_loan_membership.member
    group_loan = group_loan_membership.group_loan
    
    if default_payment.is_defaultee == true 
      return nil
    end
    
    zero_value = BigDecimal("0")
    if savings_withdrawal > member.total_savings or
      savings_withdrawal < zero_value or
      cash < zero_value or
      (cash + savings_withdrawal < default_payment.total_amount) or 
      (default_payment.is_defaultee == true ) or 
      (group_loan.is_closed == true) #if the group loan is closed, no more transactions 
      return nil
    end
    
    result_resolve= TransactionActivity.resolve_transaction_case_for_default_payment(cash,  savings_withdrawal,  default_payment )
    
    
    new_hash = {}
    new_hash[:total_transaction_amount] = result_resolve[:total_transaction_amount]
    new_hash[:transaction_case]  = result_resolve[:transaction_case]
    new_hash[:creator_id] = current_user.id 
    new_hash[:office_id] = current_user.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id

    transaction_activity = TransactionActivity.create new_hash
    
    default_payment.transaction_id = transaction_activity.id
    default_payment.is_paid = true
    default_payment.save 
    
    transaction_activity.create_default_resolution_payment_entries(
               cash,
               savings_withdrawal,
               default_payment,
               member
             )
    
    return transaction_activity
    
  end
  
=begin
  Group Loan, default loan resolution
=end

  def create_default_resolution_payment_entries( cash, savings_withdrawal, default_payment, member)
    # :default_payment_resolution_only_cash => 70,
    #   :default_payment_resolution_only_savings_withdrawal => 71,
    # 
    #   :default_payment_resolution_only_cash_extra_savings => 72,
    #   :default_payment_resolution_only_savings_withdrawal_extra_savings => 73,
    # 
    #   :default_payment_resolution_cash_and_savings_withdrawal => 74,
    #   :default_payment_resolution_cash_and_savings_withdrawal_extra_savings => 75,
    #   
    #   
    extra_savings = cash + savings_withdrawal - default_payment.total_amount
    # will create what the money is used for. 
    create_default_payment_transaction_entry(default_payment.total_amount ) 
    
    # listing the methods to get the $$$ 
    if self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_only_cash]
      
    elsif self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_only_savings_withdrawal]
      create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal, member)
      
    elsif self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_only_cash_extra_savings]
      create_extra_savings_from_default_payment_entry( extra_savings , member)
      
    elsif self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_only_savings_withdrawal_extra_savings]
      create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal, member)
      create_extra_savings_from_default_payment_entry( extra_savings  ,member)
      
    elsif self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_cash_and_savings_withdrawal]
      create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal, member)
      
    elsif self.transaction_case == TRANSACTION_CASE[:default_payment_resolution_cash_and_savings_withdrawal_extra_savings]
      create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal, member )
      create_extra_savings_from_default_payment_entry( extra_savings, member )
      
    end
      
  end
  
  
=begin
  create transaction entry for default loan resolution payment
=end

  def create_default_payment_transaction_entry(default_payment_amount)
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:default_loan_resolution_payment], 
                      :amount => default_payment_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
  end
  
  def create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal_amount, member)
    transaction_entry  = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal], 
                      :amount => savings_withdrawal_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
    # member.add_savings(savings_amount, SAVING_ENTRY_CODE[:no_weekly_payment_only_savings], savings_only_transaction_entry) 
    member.deduct_savings( savings_withdrawal_amount, SAVING_ENTRY_CODE[:soft_withdraw_for_default_payment] , transaction_entry )
  end
  
  def create_extra_savings_from_default_payment_entry( extra_savings, member )
    transaction_entry  = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_savings_from_default_loan_resolution_payment], 
                      :amount => extra_savings  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
    member.add_extra_savings( extra_savings, SAVING_ENTRY_CODE[:weekly_saving_extra_from_default_payment] ,transaction_entry )
  end
  
=begin
  Creating the transaction_entries associated with the transaction_activity 
=end


  def create_independent_savings_entry(savings_amount, current_user, member )
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    savings_only_transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:independent_savings_deposit], 
                      :amount => savings_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                    
    member.add_extra_savings(savings_amount, SAVING_ENTRY_CODE[:independent_savings_deposit], savings_only_transaction_entry) 

  end

  def create_only_savings_payment_entry(savings_amount, current_user, member )
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    savings_only_transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings], 
                      :amount => savings_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_extra_savings(savings_amount, SAVING_ENTRY_CODE[:no_weekly_payment_only_savings], savings_only_transaction_entry) 

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
                      
    member.add_compulsory_savings(initial_savings, SAVING_ENTRY_CODE[:initial_setup_saving]) 
            
  end
  
  
  # transaction_activity.create_loan_disbursement_entries( group_loan_product.loan_amount , 
  #                     group_loan_product.admin_fee, 
  #                     group_loan_product.initial_savings,
  #                     cashier, 
  #                     group_loan_membership.deduct_setup_payment_from_loan  )
                    
                    
  def create_loan_disbursement_entries( amount , admin_fee, initial_savings, cashier , deduct_setup_payment_from_loan, member ) 
    cashflow_book = cashier.active_job_attachment.office.cashflow_book
    
   
    
    if deduct_setup_payment_from_loan 
       deduction_amount = amount - self.total_transaction_amount
       self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:total_loan_disbursement_amount], 
                          :amount => amount  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                          )
       self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:setup_fee_deduction_from_disbursement_amount], 
                          :amount => admin_fee  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                          )
       saving_transaction_entry = self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:initial_savings], 
                          :amount => initial_savings  ,
                          :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                          )
                          
       member.add_compulsory_savings( initial_savings , SAVING_ENTRY_CODE[:initial_setup_saving], saving_transaction_entry) 
      
    else
      self.transaction_entries.create( 
                          :transaction_entry_code => TRANSACTION_ENTRY_CODE[:total_loan_disbursement_amount], 
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
    
    saving_transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_saving], 
                      :amount => group_loan_product.min_savings,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_interest], 
                      :amount => group_loan_product.interest,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
    
    # each saving should be able to be traced to the transaction_entry -> transaction_activity 
    member.add_compulsory_savings(group_loan_product.min_savings, SAVING_ENTRY_CODE[:weekly_saving_from_basic_payment], saving_transaction_entry) 
  end
  
  def create_extra_savings_entries( balance , current_user , member)
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_weekly_saving], 
                      :amount => balance ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_extra_savings(balance, SAVING_ENTRY_CODE[:weekly_saving_extra_from_basic_payment], saving_entry) 
  end
  
  def create_soft_savings_withdrawal_entries( savings_withdrawal, current_user , member)
    cashflow_book = current_user.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal], 
                      :amount => savings_withdrawal ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
                      
    # update member savings , add saving entries 
    member.deduct_extra_savings( savings_withdrawal, SAVING_ENTRY_CODE[:soft_withdraw_to_pay_basic_weekly_payment],saving_entry )
    
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
                  
                  
      # transaction_amount  = cash + savings_withdrawal
      transaction_amount  = cash 
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
                 
                  
      # transaction_amount  = cash + savings_withdrawal
      transaction_amount  = cash 
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
  
  def self.resolve_transaction_case_for_default_payment(cash,  savings_withdrawal,  default_payment )
     #    6 cases
     # :default_payment_resolution_only_cash => 70,
     # :default_payment_resolution_only_savings_withdrawal => 71,
     # 
     # :default_payment_resolution_only_cash_extra_saving => 72,
     # :default_payment_resolution_only_savings_withdrawal_extra_savings => 73,
     # 
     # :default_payment_resolution_cash_and_savings_withdrawal => 74,
     # :default_payment_resolution_cash_and_savings_withdrawal_extra_savings => 75
    result_resolve = {}
    result_resolve[:total_transaction_amount] = cash
    zero_value = BigDecimal("0")
    if savings_withdrawal == zero_value
      if cash  ==  default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_only_cash]
      elsif cash > default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_only_cash_extra_savings]
      end
    end
    
    if cash == zero_value
      if savings_withdrawal  ==  default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_only_savings_withdrawal]
      elsif cash > default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_only_savings_withdrawal_extra_savings]
      end
    end
    
    if cash != zero_value && savings_withdrawal != zero_value
      if (cash+ savings_withdrawal) == default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_cash_and_savings_withdrawal]
      elsif (cash+ savings_withdrawal) > default_payment.total_amount
        result_resolve[:transaction_case] = TRANSACTION_CASE[:default_payment_resolution_cash_and_savings_withdrawal_extra_savings]
      end
    end
    
    
     # result_resolve[:total_transaction_amount]
     #     new_hash[:transaction_case]  = result_resolve[:transaction_case]
     
     return result_resolve
     
  end
  
  def self.legitimate_structured_multiple_weeks_payment?( cash, savings_withdrawal, number_of_weeks, 
          basic_weekly_payment, total_savings )
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
