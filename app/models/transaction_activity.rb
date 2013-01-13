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
  
  def member
    Member.find_by_id( self.member_id )
  end
  
  def grace_payment_savings_withdrawal_amount
    transaction_entries = self.transaction_entries.where(
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_soft_savings_withdrawal] ,
      :is_deleted => false 
    )
    
    total_amount = BigDecimal("0")
    
    transaction_entries.each do |te|
      total_amount += te.amount
    end
    
    return total_amount
  end
  
  def grace_payment_extra_savings_amount
    transaction_entries = self.transaction_entries.where(
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_extra_savings] ,
      :is_deleted => false 
    )
    
    total_amount = BigDecimal("0")
    
    transaction_entries.each do |te|
      total_amount += te.amount
    end
    
    return total_amount
  end
  
  
  
  def savings_withdrawal_amount
    transaction_entries = self.transaction_entries.where(
      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal],
      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward],
      :is_deleted => false 
    )
    
    total_amount = BigDecimal("0")
    
    transaction_entries.each do |te|
      total_amount += te.amount
    end
    
    return total_amount
  end
  
  # def number_of_weeks_paid
  #   MemberPayment.where(:transaction_activity_id => self.id ).count 
  # end
  
  
  def number_of_backlogs_paid_in_weekly_cycle
    BacklogPayment.where( :is_cleared  => true ,
      :clearance_period => BACKLOG_CLEARANCE_PERIOD[:in_weekly_payment_cycle],
      :transaction_activity_id_for_backlog_clearance => self.id).count
  end
  
  def number_of_backlogs_paid
     
    BacklogPayment.where( :is_cleared  => true ,
      :clearance_period => BACKLOG_CLEARANCE_PERIOD[:in_grace_period],
      :transaction_activity_id_for_backlog_clearance => self.id).count
  end
  
  
  def group_loan_membership
    member = Member.find_by_id self.member_id 
    group_loan = GroupLoan.find_by_id  self.loan_id
    return  group_loan.get_membership_for_member( member )
  end
  
  def weekly_cycle_period_backlogs_paid_amount
    group_loan_membership = self.group_loan_membership
    number_of_backlogs_paid_in_weekly_cycle * group_loan_membership.group_loan_product.total_weekly_payment
  end
  
  # def grace_period_backlogs_paid_amount
  #   group_loan_membership = self.group_loan_membership
  #   number_of_backlogs_paid * group_loan_membership.group_loan_product.grace_period_weekly_payment
  # end
  
=begin
  independent payment
=end
  def independent_payment_extra_savings_amount
    
    extra_savings_entries = self.transaction_entries.where( :transaction_entry_code => [
      TRANSACTION_ENTRY_CODE[:extra_weekly_saving],
      TRANSACTION_ENTRY_CODE[:only_savings_independent_payment] 
      ] )
    total_amount = BigDecimal("0")
    
    extra_savings_entries.each do |te|
      total_amount += te.amount
    end
    return total_amount
    
    
  end
  
  # def extra_savings_amount
  #   extra_savings_entries = self.transaction_entries.where( :transaction_entry_code => [
  #     TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings],
  #      TRANSACTION_ENTRY_CODE[:extra_weekly_saving] 
  #     ])
  #     
  #   total_amount = BigDecimal("0")
  #   
  #   extra_savings_entries.each do |te|
  #     total_amount += te.amount
  #   end
  #   return total_amount 
  # end
  
   
  def grace_payment_extra_savings_amount
    extra_savings_entries = self.transaction_entries.where( :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_extra_savings] )
    total_amount = BigDecimal("0")
    
    extra_savings_entries.each do |te|
      total_amount += te.amount
    end
    return total_amount
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
  
    # TRANSACTION_ENTRY_CODE[:grace_period_payment] ,
    # TRANSACTION_ENTRY_CODE[:grace_period_payment_soft_savings_withdrawal] ,
    # TRANSACTION_ENTRY_CODE[:grace_period_payment_extra_savings]
  def grace_payment_savings_withdrawal_amount
    savings_withdrawal_entry = self.transaction_entries.
                            where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_soft_savings_withdrawal])
    if savings_withdrawal_entry.length != 0 
      return savings_withdrawal_entry.first.amount
    else
      return BigDecimal("0")
    end
  end
  
  def number_of_weekly_payments_paid
    MemberPayment.find(:all, :conditions => {
      :transaction_activity_id => self.id ,
      :has_paid => true ,
      :no_payment => false , 
      :only_savings => false
    }).count 
  end
  
  def weekly_payments_paid_amount
    group_loan_membership = self.group_loan_membership
    number_of_weekly_payments_paid * group_loan_membership.group_loan_product.total_weekly_payment
  end
  
=begin
  GRACE PERIOD PAYMENT APPROVAL
=end
  def backlogs_associated
    BacklogPayment.where(:transaction_activity_id_for_backlog_clearance => self.id)
  end
  
  def is_approved_for_grace_period_payment?
    self.backlogs_associated.where(:is_cashier_approved => true ).count ==  self.backlogs_associated.count 
  end
  
  def approve_grace_period_payment( employee )
    if not employee.has_role?(:cashier, employee.active_job_attachment)
      return nil
    end
    
    if self.is_approved == true 
      return nil
    end
     
    self.is_approved = true 
    self.save
  end
  
  
  # only FOR TESTING!
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
    
    # this independent savings is only used in the testing.. 
    # real life.. no such thing
    # 
    
    transaction_activity.is_approved = true
    transaction_activity.save 
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
    # employee.active_job_attachment.office
    
    
    group_loan_membership.deposit = deposit
    group_loan_membership.initial_savings = initial_savings
    group_loan_membership.admin_fee = admin_fee
    group_loan_membership.has_paid_setup_fee = true
    group_loan_membership.setup_fee_transaction_id = transaction_activity.id 
    group_loan_membership.save
    
    # member.add_savings(initial_savings, SAVING_ENTRY_CODE[:initial_setup_saving]) done in the transaction
    
    return transaction_activity  
  end
  
  def self.execute_automatic_loan_disbursement( group_loan_membership , employee) 
    if not employee.has_role?(:branch_manager, employee.get_active_job_attachment)
      puts "The employee doesn't have field_worker role "
      return nil
    end
    
    puts "after the first one"
    
   
   return nil if group_loan_membership.is_active == false 
   
   # # if attendance has not been marked 
   #  if group_loan_membership.is_active == true && group_loan_membership.is_attending_loan_disbursement.nil?
   #    puts "The attendance has not been marked, glm id = #{group_loan_membership.id}"
   #    puts "#{group_loan_membership.id} is active: #{group_loan_membership.is_active}"
   #    puts "#{group_loan_membership.id} attendance : #{group_loan_membership.is_attending_loan_disbursement}"
   #    return nil
   #  end
   #  puts "After the third one"
   #  
   #  
   #  if group_loan_membership.is_attending_loan_disbursement == false && 
   #    ( not   ( group_loan_membership.final_loan_disbursement_attendance.nil?  or   
   #     group_loan_membership.final_loan_disbursement_attendance==false) )
   #    
   #    return nil
   #  end
   
   if not group_loan_membership.final_loan_disbursement_attendance.nil? and 
       group_loan_membership.final_loan_disbursement_attendance != true 
     return nil
   end
  
  puts "After the fourth one"
  group_loan_product = group_loan_membership.group_loan_product
  member = group_loan_membership.member
  
  initial_savings = group_loan_product.initial_savings
  
  
    
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
    
    puts "received loan disbursement"
    group_loan_membership.has_received_loan_disbursement = true
    group_loan_membership.loan_disbursement_transaction_id = transaction_activity.id 
    group_loan_membership.save 
    
   
    
    return transaction_activity 
  end
  
  
  def self.execute_loan_disbursement( group_loan_membership , employee)
    # can only be executed by cashier  # wrong. latest update -> By field worker.
    # cashier passed the $$$ to the field worker. 
    # field worker give it to the member. pass the remaining to the cashier
    # if there is member absent during the disbursement 
    if not employee.has_role?(:field_worker, employee.get_active_job_attachment)
      puts "The employee doesn't have field_worker role "
      return nil
    end
    
  
   if group_loan_membership.is_active == false
     puts "The glm is not active. glm id = #{group_loan_membership.id}"
     return nil
   end
   
   # if attendance has not been marked 
   if group_loan_membership.is_active == true && group_loan_membership.is_attending_loan_disbursement.nil?
     puts "The attendance has not been marked, glm id = #{group_loan_membership.id}"
     puts "#{group_loan_membership.id} is active: #{group_loan_membership.is_active}"
     puts "#{group_loan_membership.id} attendance : #{group_loan_membership.is_attending_loan_disbursement}"
     return nil
   end
   
   
   if group_loan_membership.is_attending_loan_disbursement == false && ( not   ( group_loan_membership.final_loan_disbursement_attendance.nil?  or   group_loan_membership.final_loan_disbursement_attendance==false) )
     
     return nil
   end
    
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member
    
    initial_savings = group_loan_product.initial_savings
    
    
    
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
    
    puts "received loan disbursement"
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
  
  def TransactionActivity.create_savings_only_weekly_payment(member,weekly_task, savings_amount,  employee , revision_transaction)
    if not TransactionActivity.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, employee )
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
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id

    transaction_activity = TransactionActivity.create new_hash 
    
    if transaction_activity.nil?
      return nil
    else
      
      if revision_transaction == false 
        MemberPaymentHistory.create_weekly_payment_history_entry(
          employee,  # creator 
          weekly_task,  # period object 
          group_loan,  # the loan product
          LOAN_PRODUCT[:group_loan],
          member, # the member who paid 
          savings_amount,  #  the cash passed
          BigDecimal('0'), # savings withdrawal used
          0, # in grace payment, number of weeks is nil 
          0, # in grace payment, number of weeks is nil 
          transaction_activity.id, # the self 
          REVISION_CODE[:original_only_savings],
          PAYMENT_PHASE[:weekly_payment] 
        )
       end
     end
    
    transaction_activity.create_only_savings_payment_entry(savings_amount, employee, member )

    weekly_task.create_weekly_payment_declared_as_only_savings( member, transaction_activity, savings_amount )

 
    return transaction_activity
  end
  
  def TransactionActivity.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, employee )
    if  (not employee.has_role?(:field_worker, employee.get_active_job_attachment) ) or
        ( not weekly_task.member_payment_can_be_started?  )
        return false
    else
      return true
    end
  end
    

  
  def TransactionActivity.create_weekly_extra_savings_only( weekly_task, 
    group_loan_membership, employee, amount  )
    zero_value = BigDecimal("0")
    return nil if weekly_task.nil? or group_loan_membership.nil? or employee.nil? or amount.nil?
    return nil if amount <= zero_value 
    return nil if not  employee.has_role?(:field_worker, employee.get_active_job_attachment)
    
    member = group_loan_membership.member 
    
    return nil if not weekly_task.has_paid_weekly_payment?(member)
    
    transaction_case = self.resolve_independent_payment_transaction_case(
      amount, 
      BigDecimal('0'), 
      amount, 
      0,
      0
    )
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = amount
    new_hash[:transaction_case] = transaction_case
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    # new_hash[:loan_type] = 
    #    new_hash[:loan_id] = 
    
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_extra_savings_entries( amount , employee, member )
    #  create member payment
    
    weekly_task.create_extra_savings_only_payment( member, transaction_activity, amount) 
    
    return transaction_activity
  end
  
  
  def approve_payment(employee)
    if  not employee.has_role?(:cashier, employee.get_active_job_attachment)
      return nil
    end
    
    self.is_approved = true
    self.approver_id = employee.id 
    self.save 
  end
  
  
  
=begin
##################################################################################
######################################### WEEKLY PAYMENT
##################################################################################
=end
  def TransactionActivity.can_create_savings_withdrawal_for_group_weekly_payment?(group_loan_membership , revision_transaction)
    # no savings withdrawal is allowed if there is unapproved transaction 
    pending_approval_group_weekly_payment = group_loan_membership.unapproved_group_weekly_payment
    pending_approval_transactions_id_list = TransactionActivity.where(:member_id => group_loan_membership.member_id, 
                        :is_deleted => false, 
                        :is_canceled => false , 
                        :is_approved => false).map{|x| x.id }
        
  
    # case when savings withdrawal is rejected
    # if weekly payment edit 
      # 1. if there is no other pending approval, only itself == allow 
      # 2. if there is other pending approval , not itself == not allow
      
    # If weekly payment creation
      # 1. if there is other pending approval, not itself -> not allow
      # 2. if there is no other pending approval.. allow 

                
    if revision_transaction == true
      if pending_approval_transactions_id_list.length > 1
        return false
      elsif pending_approval_transactions_id_list.length == 1 and pending_approval_group_weekly_payment.nil?
        return false 
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first != pending_approval_group_weekly_payment.id
        return false
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first == pending_approval_group_weekly_payment.id
          # please proceed to the group weekly payment revision  
          return true 
      end

    elsif revision_transaction == false  # new weekly payment creation
      if pending_approval_transactions_id_list.length > 1
        return false
      elsif pending_approval_transactions_id_list.length == 1 and pending_approval_group_weekly_payment.nil?
        return false
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first != pending_approval_group_weekly_payment.id
        return false
      end
    end
    
    return true 
  end
  
  def TransactionActivity.create_generic_weekly_payment(
          weekly_task, 
          group_loan_membership,
          employee,
          cash,
          savings_withdrawal, 
          number_of_weeks,
          number_of_backlogs,
          revision_transaction ) # we need this weekly_task info.. which week?
          
    group_loan = group_loan_membership.group_loan
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member 
    zero_value = BigDecimal("0")
          
    return nil if weekly_task.nil? or
                  group_loan_membership.nil? or
                  employee.nil? or 
                  cash.nil? or
                  savings_withdrawal.nil? or 
                  number_of_weeks.nil? or 
                  number_of_backlogs.nil?
                  
    return nil if not WeeklyTask.valid_weekly_task_payment?(weekly_task, 
                                group_loan_membership, 
                                number_of_weeks, 
                                number_of_backlogs)
    
    return nil if group_loan_membership.is_active == false 
    return nil if not employee.has_role?(:field_worker, employee.get_active_job_attachment)
    return nil if savings_withdrawal > member.saving_book.total_extra_savings
    
    # no savings withdrawal is allowed if there is unapproved transaction 
    pending_approval_group_weekly_payment = group_loan_membership.unapproved_group_weekly_payment
    pending_approval_transactions_id_list = TransactionActivity.where(:member_id => member.id, 
                        :is_deleted => false, 
                        :is_canceled => false , 
                        :is_approved => false).map{|x| x.id }
                        
    if savings_withdrawal > BigDecimal('0')
      if not TransactionActivity.can_create_savings_withdrawal_for_group_weekly_payment?(group_loan_membership ,revision_transaction)
        return nil
      end 
    end
    
     # there can only be 1 payment for a given weekly meeting 
    return nil if  weekly_task.transactions_for_member(member).count != 0
   
   
    total_amount_paid = cash + savings_withdrawal
    total_payable = ( number_of_weeks + number_of_backlogs)  * group_loan_product.total_weekly_payment  
    
    
    return nil if total_amount_paid <  total_payable
    
    extra_savings = total_amount_paid - total_payable 
    
    #  create the transaction 
    # what if there is duplicate payment? can't be... we are keeping track of total unpaid  weekly  + total backlogs
    # the followings are bullshit 
    
    #STEPS TO BE DONE
    # => 1. Create the transaction activity
    # => 2. mark the weekly task fulfilment or backlog payment fulfilment accordingly  
    # => 3. Create the transaction entries 
      # 
    # DONE! return the transaction activity 
        
    new_hash = {}
    
  
    result_resolve = self.resolve_transaction_case(
      cash, 
      savings_withdrawal, 
      extra_savings, 
      number_of_weeks,
      number_of_backlogs
    )
    
    
    # transaction_amount  == money exchanging hands 
    # make it easier for the cashier to count the $$$, given from the fieldworker
    new_hash[:total_transaction_amount] = cash 
    new_hash[:transaction_case]  = result_resolve    
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    # then, create the entries
    # 
    
    transaction_activity = TransactionActivity.create new_hash 
    
    if transaction_activity.nil?
      return nil
    else
      if revision_transaction == false 
        MemberPaymentHistory.create_weekly_payment_history_entry(
          employee,  # creator 
          weekly_task,  # period object 
          group_loan,  # the loan product
          LOAN_PRODUCT[:group_loan],
          member, # the member who paid 
          cash,  #  the cash passed
          savings_withdrawal, # savings withdrawal used
          number_of_weeks, # in grace payment, number of weeks is nil 
          number_of_backlogs, # in grace payment, number of weeks is nil 
          transaction_activity.id, # the self 
          REVISION_CODE[:original_normal],
          PAYMENT_PHASE[:weekly_payment] 
        ) 
      end
    end
    
    
    
    
    
    #  creating the single or multiple weeks payment 
 
    if number_of_weeks == 1 
      weekly_task.create_basic_weekly_payment( member, transaction_activity, cash, false)
    elsif number_of_weeks > 1 
      weekly_task.create_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash, false )
    end
    
    
    # creating the backlog payment 
    # we haven't updated the member payment 
    # there is a method -> weekly_task#total_cash_received << how? 
    # need to capture: backlog payment + extra cash, linked to that week
    if number_of_backlogs > 0
      
      member.backlog_payments_for_group_loan(group_loan).where(:is_cleared => false ).order("created_at ASC").limit( number_of_backlogs ).each do |x|
         x.is_cleared  = true 
         x.clearance_period = BACKLOG_CLEARANCE_PERIOD[:in_weekly_payment_cycle]
         x.backlog_cleared_declarator_id = employee.id 
         x.transaction_activity_id_for_backlog_clearance = transaction_activity.id
         x.save
         weekly_task.create_backlog_payment(member, transaction_activity, cash, false)
      end 
    end
    
    # creating the transaction entries
    # create transaction entries: basic entry, savings withdrawal, extra savings 
    # or even the backlog entries 
    # 1. according to the number_of_weeks, create basic weekly payment entries 
    # 2 . according to the number of backlogs, create backlog payment
    (number_of_weeks + number_of_backlogs).times do |x|
      transaction_activity.create_basic_payment_entries(group_loan_product, employee, member) 
    end
    
    # 3. according to the savings withdrawal, create savings withdrawal entry
    if savings_withdrawal > zero_value 
      transaction_activity.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
    end
    
    # 4 . according to the extra savings, create extra savings
    if extra_savings > zero_value
      transaction_activity.create_extra_savings_entries(extra_savings, employee, member )
    end
    
    
    return transaction_activity
  end 
   
  
 
   
   
    
    
  def revert_transaction_effect(member_payment)
    puts "IN REVERT\n"*10
    if member_payment.is_full_payment? or member_payment.is_backlog_full_payment?
      puts "IN FULL PAYMENT"
      
      if member_payment.is_full_payment? 
        puts "because of the full payment"
      elsif member_payment.is_backlog_full_payment?
        puts "because of the backlog full payment"
      end
      # there are basic payment entries created (multiple week and multiple backlog payments? )
        # for all basic payment entries, 
          # revert the compulsory savings generated 
            self.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_saving]).each do |te|
              te.revert_and_delete
            end
          # revert the income from interest generated (affecting the cashflow book). for now, we are not handling it yet
          # revert the cost of sales in the form of principal  # we are not handling it yet 
      # there are some extra savings
        # revert the extra savings generated 
          self.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_weekly_saving]).each do |te|
            te.revert_and_delete
          end
      # there are some savings withdrawal 
        # revert the effect of savings withdrawal 
        self.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal]).each do |te|
          te.revert_and_delete
        end
        # and reduce the account payable in the cashflow book.. 
    elsif member_payment.only_savings_payment?
      puts "IN ONLY SAVINGS PAYMENT"
      # only extra savings.. revert the effect: delete the saving entry ,delete the transaction entry 
      self.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings]).each do |te|
        te.revert_and_delete
      end
      # reduce the account payable in the cashflow book 
    elsif member_payment.only_savings_independent_payment?
    
      puts "1234 in the revert transaction effect, only savings independent payment "
      self.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:only_savings_independent_payment]).each do |te|
        te.revert_and_delete
      end
    end
     
  end
  
  def revert_member_payment_effect(member_payment)
    if member_payment.is_full_payment? or member_payment.is_backlog_full_payment?
      # might cleared several member payments (from present and future weekly payment)
      BacklogPayment.where(:transaction_activity_id_for_backlog_clearance => self.id).each do |x|
        x.is_cleared  = false  
        x.clearance_period = nil 
        x.backlog_cleared_declarator_id =  nil 
        x.transaction_activity_id_for_backlog_clearance =  nil
        x.save 
      end
      # might paid several future payments
      MemberPayment.where(:transaction_activity_id => self.id).each do |member_payment|
        member_payment.destroy 
      end
    elsif member_payment.only_savings_payment? or member_payment.no_payment? 
      #  created 1 backlog payment 
      BacklogPayment.where(:member_payment_id => member_payment.id, :is_cleared => false ).each do |x|
        x.destroy 
      end 
      
      #  created 1 weekly payment 
      MemberPayment.where(:transaction_activity_id => self.id).each do |member_payment|
        member_payment.destroy 
      end
    elsif member_payment.only_savings_independent_payment?
      MemberPayment.where(:transaction_activity_id => self.id).each do |member_payment|
        member_payment.destroy 
      end 
    end
  end
  
   
  
  def extra_savings_withdrawal_transaction_entries
    self.transaction_entries.where( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal],  
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
  end

  def extra_savings_withdrawal_amount
    return self.transaction_entries.where( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal],  
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      ).sum("amount")
  end
  
  def extra_savings_addition_transaction_entries 
    self.transaction_entries.where( 
                      :transaction_entry_code => [
                          TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings],
                           TRANSACTION_ENTRY_CODE[:extra_weekly_saving] 
                          ],  
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
  end
  
  def extra_savings_addition_amount
    
    
    
    return self.transaction_entries.where( 
                      :transaction_entry_code => [
                          TRANSACTION_ENTRY_CODE[:no_weekly_payment_only_savings],
                           TRANSACTION_ENTRY_CODE[:extra_weekly_saving] 
                          ],  
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      ).sum("amount")
  end
  
  def initial_extra_savings_before_current_transaction 
    self.member.saving_book.total_extra_savings  - self.extra_savings_addition_amount + self.extra_savings_withdrawal_amount 
  end
  
=begin
  INDEPENDENT 
=end 


  
  def number_of_weeks_paid
    current_transaction = self 
    MemberPayment.where{
      # (is_independent_weekly_payment.eq false ) & 
      (week_number.not_eq nil) & # not backlog payment 
      (transaction_activity_id.eq current_transaction.id  )
    }.count 
  end
  
  # def number_of_backlogs_paid 
  #   current_transaction = self 
  #   MemberPayment.where{
  #     (is_independent_weekly_payment.eq false ) & 
  #     (week_number.eq nil) & # backlog payment. the week number is nil because the week itself is declared as no payment 
  #     (transaction_activity_id.eq current_transaction.id  )
  #   }.count
  # end 
  
  
  # all transaction type (normal, only savings, and no payment) to generic
  def TransactionActivity.update_generic_weekly_payment(
          weekly_task, 
          group_loan_membership,
          employee,
          cash,
          savings_withdrawal, 
          number_of_weeks,
          number_of_backlogs  ) 
          # current_transaction_activity can be nil
          # hence, we have to ensure that the week payment is declared as no payment declaration.
          # if it is not declared as no payment, then fuck it... it is fraud transaction 
          
      group_loan = group_loan_membership.group_loan
      

      return nil if weekly_task.nil? or
                    group_loan_membership.nil? or
                    employee.nil? or 
                    cash.nil? or
                    savings_withdrawal.nil? or 
                    number_of_weeks.nil? or 
                    number_of_backlogs.nil?  
             
      member = group_loan_membership.member       
      return nil if not weekly_task.has_paid_weekly_payment?(member) 
      
      
      member_payment =  weekly_task.member_payment_for(member) # will only return member payment for a given week 
      return nil if member_payment.nil? 
      # done with background check 
      return nil if not employee.has_role?(:field_worker, employee.get_active_job_attachment)
      return nil if group_loan_membership.is_active == false
      
      
      
      
       
      # return nil if current_transaction_activity.nil? and (not member_payment.no_payment?)
      # return nil if not current_transaction_activity.nil? and not weekly_task.valid_transaction_activity?( current_transaction_activity )
      
      group_loan_product = group_loan_membership.group_loan_product
       
      zero_value = BigDecimal("0")
      member = group_loan_membership.member
      
      
      current_transaction = weekly_task.transactions_for_member(member).first 
      
      new_transaction = nil
      revision_code = nil 
      if member_payment.is_full_payment? or member_payment.only_savings_payment?
        
        return nil if current_transaction.nil? 
        
        # we need to revert the transaction effect: member savings withdrawal and extra savings 
        puts "Reverting the transaction effect"
        current_transaction.revert_transaction_effect(member_payment)
        
        current_transaction.revert_member_payment_effect( member_payment ) 
        
        # we need to revert the member payment effect: backlog creation and member payments creation 

        current_transaction.is_deleted = true 
        current_transaction.save

        if member_payment.is_full_payment? 
          revision_code = REVISION_CODE[:normal][:normal]
        elsif member_payment.only_savings_payment?
          revision_code = REVISION_CODE[:only_savings][:normal]
        end
        

        # current_transaction.replace_transaction( new_transaction )
        
        
      elsif member_payment.no_payment? 
        # revert the transaction effect. 
        # hey, no transaction is created in the first place. it is just the member payment 
        BacklogPayment.where(:member_payment_id => member_payment.id ).each do |x|
          x.destroy 
        end
        
        member_payment.destroy 
        
        revision_code = REVISION_CODE[:no_payment][:normal]
        
      else 
        return nil
      end
      
      member.reload 
    
      new_transaction = TransactionActivity.create_generic_weekly_payment(
              weekly_task, 
              group_loan_membership,
              employee,
              cash,
              savings_withdrawal, 
              number_of_weeks,
              number_of_backlogs,
              true )

      if new_transaction.nil?
        raise ActiveRecord::Rollback, "Call tech support!"  # <<< THIS IS THE SHITE!!!! 
        return nil 
      end
      
      
      MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        weekly_task,  # period object 
        group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        cash,  #  the cash passed
        savings_withdrawal, # savings withdrawal used
        number_of_weeks, # in grace payment, number of weeks is nil 
        number_of_backlogs, # in grace payment, number of weeks is nil 
        new_transaction.id, # the self 
        revision_code,
        PAYMENT_PHASE[:weekly_payment]
        )
       
      return new_transaction  
  end
   
   
   # all payment type ( no payment, normal, only savings) to  only savings
  def TransactionActivity.update_savings_only_weekly_payment(member,weekly_task, savings_amount,  employee )
    if not TransactionActivity.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, employee )
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
    
    # extract the current transaction activity 
    current_transaction = weekly_task.transactions_for_member(member).first 
    member_payment =  weekly_task.member_payment_for(member)
    new_transaction = nil
    revision_code   = nil 
    if member_payment.is_full_payment? or member_payment.only_savings_payment?
      
      if member_payment.is_full_payment?
        revision_code   = REVISION_CODE[:normal][:only_savings] 
      elsif member_payment.only_savings_payment?
        revision_code   = REVISION_CODE[:only_savings][:only_savings] 
      end
      
      return nil if current_transaction.nil? 
      
      # we need to revert the transaction effect: member savings withdrawal and extra savings 
      current_transaction.revert_transaction_effect(member_payment)
      
      current_transaction.revert_member_payment_effect( member_payment ) 
      
      # we need to revert the member payment effect: backlog creation and member payments creation 

      current_transaction.is_deleted = true 
      current_transaction.save
       
    elsif member_payment.no_payment? 
      # revert the transaction effect. 
      # hey, no transaction is created in the first place. it is just the member payment 
      BacklogPayment.where(:member_payment_id => member_payment.id ).each do |x|
        x.destroy 
      end
      
      revision_code   = REVISION_CODE[:no_payment][:only_savings] 
      
      member_payment.destroy 
      
    else 
      return nil
    end
    
    revision_transaction = true
    
    member.reload 
    new_transaction = TransactionActivity.create_savings_only_weekly_payment(member,weekly_task, savings_amount,  employee , revision_transaction )

    if new_transaction.nil?
      raise ActiveRecord::Rollback, "Call tech support!"  # <<< THIS IS THE SHITE!!!! , cancel all the previous changes 
      return nil 
    end
  
     
   
    MemberPaymentHistory.create_weekly_payment_history_entry(
      employee,  # creator 
      weekly_task,  # period object 
      group_loan,  # the loan product
      LOAN_PRODUCT[:group_loan],
      member, # the member who paid 
      savings_amount,  #  the cash passed
      BigDecimal('0'), # savings withdrawal used
      0, # in grace payment, number of weeks is nil 
      0, # in grace payment, number of weeks is nil 
      new_transaction.id, # the self 
      revision_code, #  REVISION_CODE[:original_only_savings],
      PAYMENT_PHASE[:weekly_payment] 
    )  
   
    
 
    return new_transaction
  end
  
  
  
=begin
##################################################################################
######################################### INDEPENDENT PAYMENT
##################################################################################
=end
  def TransactionActivity.create_only_extra_savings_independent_payment(
      group_loan_membership,
      employee,
      amount,
      revision_transaction )
    zero_value = BigDecimal("0")
    return nil if group_loan_membership.nil? or employee.nil? or amount.nil? 
    return nil if amount <= zero_value 
    return nil if not  employee.has_role?(:field_worker, employee.get_active_job_attachment)
    
     
    member = group_loan_membership.member 
    
    # THERE CAN ONLY BE 1 un approved independent payment for a member at a given time 
    # There can be 1 weekly payment and 1 independent payment running at once. However, 
    # if there are both of then, independent payment can't perform savings withdrawal 
    pending_approval_independent_payment = group_loan_membership.unapproved_independent_payment 
    return nil if not pending_approval_independent_payment.nil?
    
    group_loan = group_loan_membership.group_loan 
    weekly_task = group_loan.currently_executed_weekly_task
    return nil if weekly_task.nil? 
    
    transaction_case = self.resolve_independent_payment_transaction_case(
      amount, 
      BigDecimal('0'), 
      amount, 
      0,
      0
    )
  
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = amount
    new_hash[:transaction_case] = transaction_case
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id 
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    
    transaction_activity = TransactionActivity.create new_hash 
    # transaction_activity.create_extra_savings_entries( amount , employee, member )
    
    transaction_activity.create_extra_savings_entries_from_only_savings_independent_payment( amount , employee, member )
    #  create member payment
    
    weekly_task.create_extra_savings_only_independent_payment( member, transaction_activity, amount) 
    # create the payment history 
    
    if not revision_transaction
      MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        weekly_task,  # period object 
        group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        amount,  #  the cash passed
        BigDecimal('0'), # savings withdrawal used
        0, # in independent payment only savings, number of weeks is nil 
        0, # in independent payment only savings, number of weeks is nil 
        transaction_activity.id, # the self 
        REVISION_CODE[:original_independent_only_savings],
        PAYMENT_PHASE[:independent_payment]
        )
    end
    
    return transaction_activity
  end
  
  
  def TransactionActivity.update_only_extra_savings_independent_payment(
      group_loan_membership,
      employee,
      amount) # extract the pending approval independent payment
      # there can only be one 
      
      # setup the pre condition 
      zero_value = BigDecimal("0")
      return nil if group_loan_membership.nil? or employee.nil? or amount.nil?  
      # details of the pre condition is handled by the creation itself 
       
      # extract the current un approved independent payment, not deleted nor canceled (TransactionActivity)
      pending_approval_independent_payment = group_loan_membership.unapproved_independent_payment 
      return nil if pending_approval_independent_payment.nil?
      
      member_payment = MemberPayment.where(:transaction_activity_id =>pending_approval_independent_payment.id ).first
      
      
      puts "------- analysis of member payment\n"
      if member_payment.only_savings_independent_payment?
        puts "IT IS TRUE< ONLY savings independent payment"
      end
      weekly_task = member_payment.weekly_task 
      
      pending_approval_independent_payment.revert_transaction_effect(member_payment)
      # pending_approval_independent_payment.transaction_entries.each do |te|
      #   te.revert_and_delete
      # end
      
      pending_approval_independent_payment.revert_member_payment_effect(member_payment)
      
      # MemberPayment.where(:transaction_activity_id => pending_approval_independent_payment.id).each do |member_payment|
      #   member_payment.destroy 
      # end
      
      pending_approval_independent_payment.is_deleted = true 
      pending_approval_independent_payment.save

      if member_payment.is_full_payment? 
        revision_code = REVISION_CODE[:independent_only_savings][:normal]
      elsif member_payment.only_savings_independent_payment?
        revision_code = REVISION_CODE[:independent_only_savings][:only_savings]
      end
      # revert_independent_transaction_effect
      # revert_independent_payment_effect  -> backlog payment, future payment, etc 
    
      # delete the current transaction 
      
      # create the new one
      # if successful, ok good.. 
      # if fails, rollback the whole transaction  
   
      member = group_loan_membership.member
      member.reload
      
      group_loan_membership.reload 
      new_transaction = TransactionActivity.create_only_extra_savings_independent_payment(
              group_loan_membership,
              employee,
              amount,
              true )

      if new_transaction.nil?
        raise ActiveRecord::Rollback, "Call tech support!"  # <<< THIS IS THE SHITE!!!! 
        return nil 
      end
      
      
      MemberPaymentHistory.create_weekly_payment_history_entry(
          employee,  # creator 
          weekly_task,  # period object 
          group_loan_membership.group_loan,  # the loan product
          LOAN_PRODUCT[:group_loan],
          member, # the member who paid 
          amount,  #  the cash passed
          BigDecimal('0'), # savings withdrawal used
          0, # in grace payment, number of weeks is nil 
          0, # in grace payment, number of weeks is nil 
          new_transaction.id, # the self 
          revision_code,
          PAYMENT_PHASE[:independent_payment]
        )
       
      return new_transaction  
  end
  
  
  
  def TransactionActivity.create_generic_independent_payment(
          group_loan_membership,
          employee,
          cash, 
          savings_withdrawal,
          number_of_weeks,
          number_of_backlogs,
          revision_transaction)
    group_loan = group_loan_membership.group_loan
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member 
    zero_value = BigDecimal("0") 
      
    return nil if group_loan_membership.nil? or
                  employee.nil? or 
                  cash.nil? or
                  savings_withdrawal.nil? or 
                  number_of_weeks.nil? or 
                  number_of_backlogs.nil?
                  
    
    return nil if not WeeklyTask.valid_duration?( group_loan_membership, number_of_weeks, number_of_backlogs)
    return nil if group_loan_membership.is_active == false 
    return nil if not employee.has_role?(:field_worker, employee.get_active_job_attachment)
    return nil if savings_withdrawal > member.saving_book.total_extra_savings
    
    # if there is any unaproved independent payment, no further 
    pending_approval_independent_payment = group_loan_membership.unapproved_independent_payment 
    return nil if not pending_approval_independent_payment.nil?
    
    # if there is any other unapproved transaction, no savings withdrawal 
    if savings_withdrawal > zero_value 
      if group_loan_membership.total_unapproved_payment != 0 
        return nil
      end
    end
    
    
    total_amount_paid = cash + savings_withdrawal
    total_payable = ( number_of_weeks + number_of_backlogs)  * group_loan_product.total_weekly_payment  
    
    return nil if total_amount_paid <  total_payable
    
    extra_savings = total_amount_paid - total_payable
    weekly_task = group_loan.currently_executed_weekly_task
    
    return nil if weekly_task.nil?
    new_hash = {}
    
  
    result_resolve = self.resolve_independent_payment_transaction_case(
      cash, 
      savings_withdrawal, 
      extra_savings, 
      number_of_weeks,
      number_of_backlogs
    )
    
    
    # transaction_amount  == money exchanging hands 
    # make it easier for the cashier to count the $$$, given from the fieldworker
    new_hash[:total_transaction_amount] = cash 
    new_hash[:transaction_case]  = result_resolve
    
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    # then, create the entries
    # 
    
    transaction_activity = TransactionActivity.create new_hash
    
 
 #no weekly task. only take the group loan info from transaction activity
    # if number_of_weeks > 0 
    #   weekly_task.create_independent_group_weekly_payment( member, transaction_activity, number_of_weeks, cash)
    # end
    
    # if number_of_weeks == 1 
    #   weekly_task.create_independent_group_single_week_payment( member, transaction_activity, cash)
    # elsif number_of_weeks > 1 
    #   weekly_task.create_independent_group_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash)
    # end
    
    
    if number_of_weeks == 1 
      weekly_task.create_basic_weekly_payment( member, transaction_activity, cash, true )
    elsif number_of_weeks > 1 
      weekly_task.create_multiple_weeks_payment( member, transaction_activity, number_of_weeks, cash, true )
    end
    
    
    
 
    
    
    
    if number_of_backlogs > 0
      
      member.backlog_payments_for_group_loan(group_loan).where(:is_cleared => false ).order("created_at ASC").limit( number_of_backlogs ).each do |x|
         x.is_cleared  = true 
         x.clearance_period = BACKLOG_CLEARANCE_PERIOD[:in_weekly_payment_cycle]
         x.backlog_cleared_declarator_id = employee.id 
         x.transaction_activity_id_for_backlog_clearance = transaction_activity.id
         x.save
         weekly_task.create_backlog_payment( member, transaction_activity, cash,true )
      end 
    end
    
    # creating the transaction entries
    # create transaction entries: basic entry, savings withdrawal, extra savings 
    # or even the backlog entries 
    # 1. according to the number_of_weeks, create basic weekly payment entries 
    # 2 . according to the number of backlogs, create backlog payment
    (number_of_weeks + number_of_backlogs).times do |x|
      transaction_activity.create_basic_payment_entries(group_loan_product, employee, member) 
    end
    
    # 3. according to the savings withdrawal, create savings withdrawal entry
    if savings_withdrawal > zero_value 
      transaction_activity.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
    end
    
    # 4 . according to the extra savings, create extra savings
    if extra_savings > zero_value
      transaction_activity.create_extra_savings_entries(extra_savings, employee, member )
    end
    
    
     
    if not revision_transaction
      MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        weekly_task,  # period object 
        group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        cash,  #  the cash passed
        BigDecimal('0'), # savings withdrawal used
        number_of_weeks, # in independent payment only savings, number of weeks is nil 
        number_of_backlogs, # in independent payment only savings, number of weeks is nil 
        transaction_activity.id, # the self 
        REVISION_CODE[:original_independent_normal],
        PAYMENT_PHASE[:independent_payment]
        )
    end
    
    
    return transaction_activity 
  end
  
  
  
  def TransactionActivity.update_generic_independent_payment(
          group_loan_membership,
          employee,
          cash, 
          savings_withdrawal,
          number_of_weeks,
          number_of_backlogs)
    group_loan = group_loan_membership.group_loan
    group_loan_product = group_loan_membership.group_loan_product
    member = group_loan_membership.member 
    zero_value = BigDecimal("0") 
      
    return nil if group_loan_membership.nil? or
                  employee.nil? or 
                  cash.nil? or
                  savings_withdrawal.nil? or 
                  number_of_weeks.nil? or 
                  number_of_backlogs.nil?
                  
     
    # extract the current un approved independent payment, not deleted nor canceled (TransactionActivity)
    pending_approval_independent_payment = group_loan_membership.unapproved_independent_payment 
    return nil if pending_approval_independent_payment.nil?

    member_payment = MemberPayment.where(:transaction_activity_id =>pending_approval_independent_payment.id ).first

    weekly_task = member_payment.weekly_task 

    pending_approval_independent_payment.revert_transaction_effect(member_payment)
    pending_approval_independent_payment.revert_member_payment_effect(member_payment)
    pending_approval_independent_payment.is_deleted = true 
    pending_approval_independent_payment.save

    if member_payment.is_full_payment? 
      revision_code = REVISION_CODE[:independent_only_savings][:normal]
    elsif member_payment.only_savings_independent_payment?
      revision_code = REVISION_CODE[:independent_normal][:normal]
    end
    # revert_independent_transaction_effect
    # revert_independent_payment_effect  -> backlog payment, future payment, etc 

    # delete the current transaction 

    # create the new one
    # if successful, ok good.. 
    # if fails, rollback the whole transaction  

    member.reload 

    new_transaction = TransactionActivity.create_generic_independent_payment(
            group_loan_membership,
            employee,
            cash, 
            savings_withdrawal,
            number_of_weeks,
            number_of_backlogs,
            true)

    if new_transaction.nil?
      raise ActiveRecord::Rollback, "Call tech support!"  # <<< THIS IS THE SHITE!!!! 
      return nil 
    end


    MemberPaymentHistory.create_weekly_payment_history_entry(
        employee,  # creator 
        weekly_task,  # period object 
        group_loan,  # the loan product
        LOAN_PRODUCT[:group_loan],
        member, # the member who paid 
        cash,  #  the cash passed
        savings_withdrawal, # savings withdrawal used
        number_of_weeks, # in grace payment, number of weeks is nil 
        number_of_backlogs, # in grace payment, number of weeks is nil 
        new_transaction.id, # the self 
        revision_code,
        PAYMENT_PHASE[:independent_payment]
      )

    return new_transaction
    
  end
  
  

  
  def TransactionActivity.resolve_independent_payment_transaction_case( cash, savings_withdrawal, extra_savings,
                          number_of_weeks, number_of_backlogs)
                          
    prependix= "888"
    content = "" 
    zero_value = BigDecimal("0")
    
    # 77710010
    if cash > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if savings_withdrawal > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if extra_savings > zero_value
      content << 1.to_s 
    else
      content << 0.to_s 
    end
    
    if number_of_weeks == 0 
      content << 0.to_s 
    elsif number_of_weeks == 1 
      content << 1.to_s 
    elsif number_of_weeks >  1 
      content << 2.to_s 
    end
    
    if number_of_backlogs == 0 
      content << 0.to_s 
    elsif number_of_backlogs == 1
      content << 1.to_s 
    elsif number_of_backlogs > 1 
      content << 2.to_s 
    end
    
    return ( prependix + content ) .to_i 
  end
  
=begin
########################################################## 
############################# GRACE PERIOD PAYMENT 
##########################################################
=end
  
  
  
  def TransactionActivity.resolve_grace_period_transaction_case(
      cash, 
      savings_withdrawal, 
      extra_savings 
    )
    
    prependix= "666"  # backlog payment during grace period 
    content = "" 
    zero_value = BigDecimal("0")
    
    if cash > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if savings_withdrawal > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if extra_savings > zero_value
      content << 1.to_s 
    else
      content << 0.to_s 
    end
    
    
    
    return ( prependix + content ) .to_i 
  end
  
  
  def TransactionActivity.can_create_savings_withdrawal_for_group_grace_payment?(group_loan_membership , revision_transaction)
    # no savings withdrawal is allowed if there is unapproved transaction 
    pending_approval_group_grace_payment = group_loan_membership.unapproved_grace_period_payment
    pending_approval_transactions_id_list = TransactionActivity.where(:member_id => group_loan_membership.member_id, 
                        :is_deleted => false, 
                        :is_canceled => false , 
                        :is_approved => false).map{|x| x.id }
      
    puts "THe list length: #{pending_approval_transactions_id_list.length}"
    
  
    # case when savings withdrawal is rejected
    # if weekly payment edit 
      # 1. if there is no other pending approval, only itself == allow 
      # 2. if there is other pending approval , not itself == not allow
      
    # If weekly payment creation
      # 1. if there is other pending approval, not itself -> not allow
      # 2. if there is no other pending approval.. allow 

                
    if revision_transaction == true
      if pending_approval_transactions_id_list.length > 1
        return false
      elsif pending_approval_transactions_id_list.length == 1 and pending_approval_group_grace_payment.nil?
        return false 
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first != pending_approval_group_grace_payment.id
        return false
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first == pending_approval_group_grace_payment.id
          # please proceed to the group weekly payment revision  
          return true 
      end

    elsif revision_transaction == false  # new weekly payment creation
      if pending_approval_transactions_id_list.length > 1
        return false
      elsif pending_approval_transactions_id_list.length == 1 and pending_approval_group_grace_payment.nil?
        return false
      elsif pending_approval_transactions_id_list.length == 1 and  
          pending_approval_transactions_id_list.first != pending_approval_group_grace_payment.id
        return false
      end
    end
    
    return true 
  end
  
  
  
  def TransactionActivity.create_generic_grace_period_payment(
          group_loan_membership,
          employee,
          cash,
          savings_withdrawal,
          revision_transaction)
          
    puts "7123 entrance"
    
    group_loan = group_loan_membership.group_loan 
    group_loan_product = group_loan_membership.group_loan_product 
    member = group_loan_membership.member 
    default_payment = group_loan_membership.default_payment 
    zero_value = BigDecimal("0")
    
    # if glm is non active, return nil
    puts "7123 glm active"
    if group_loan_membership.is_active == false
      return nil
    end
    #in grace period, no more notion of unpaid backlogs
    puts "7123 not defaultee"
    if group_loan_membership.default_payment.is_defaultee == false 
      return nil
    end
    
    puts "7123 wrong role"
    if not employee.has_role?(:field_worker, employee.active_job_attachment )
      return nil
    end
    #  check if it grace period 
    puts "7123 in grace period"
    if not group_loan.is_grace_period?
      return nil
    end
    
    # THERE CAN ONLY BE  1 un approved grace period payment 
    puts "7123 there is pending approval transaction"
    pending_transaction = group_loan_membership.unapproved_grace_period_payment
    if revision_transaction == false 
      if not pending_transaction.nil?
        puts "9999 pending transaction is not nil "
        return nil
      end
    end
    
    
    # no savings withdrawal is allowed if there is unapproved transaction 
    puts "7123 bad savings withdrawal, un approved previous transaction activity "
    if savings_withdrawal > BigDecimal('0')
      if not TransactionActivity.can_create_savings_withdrawal_for_group_grace_payment?(group_loan_membership , revision_transaction)
        return nil
      end
      # if TransactionActivity.where(:member_id => member.id, :is_deleted => false, :is_canceled => false , 
      #                   :is_approved => false).count != 0
      #           return nil
      #       end
    end
    
    
    # check the number_of_backlogs < actual unpaid backlogs 
    # if number_of_backlogs <= 0 or ( number_of_backlogs >  group_loan_membership.unpaid_backlogs.count  )
    #   return nil
    # end
    
    # check if savings withdrawal > saving_book.extra_savings 
    puts "7123 total extra savings < saving withdrawla"
    if member.saving_book.total_extra_savings < savings_withdrawal
      return nil
    end
    
    
    # check if cash and savings withdrawal >= 0 
    puts "7123 bad cash input"
    if cash < zero_value or savings_withdrawal < zero_value 
      return nil
    end
    
    puts "7123 no payment at all "
    if cash == zero_value && savings_withdrawal == zero_value
      return nil
    end
    
    
    
    # if (cash + savings_withdrawal) < default_payment.unpaid_grace_period_amount
    
    total_payable = default_payment.unpaid_grace_period_amount
    total_amount_paid = cash + savings_withdrawal
    # check if cash + savings_withdrawal >= number_of_backlogs * group_loan_product.grace_period_weekly_payment
 
    
    extra_savings = total_amount_paid - total_payable 
    
    new_hash = {}
    
  
    result_resolve = self.resolve_grace_period_transaction_case(
      cash, 
      savings_withdrawal, 
      extra_savings
    )
    # this shit starts with 666
    
    
    # transaction_amount  == money exchanging hands 
    # make it easier for the cashier to count the $$$, given from the fieldworker
    new_hash[:total_transaction_amount] = cash 
    new_hash[:transaction_case]  = result_resolve
    
    # puts "!!@@!^@&!&@^&!^&@!!@&^@!&^ the result resolve:#{ result_resolve}\n"*10
    
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    # then, create the entries
    # 
    
    transaction_activity = TransactionActivity.create new_hash
    
    # IN GRACE PERIOD, NO NOTION ABOUT BACKLOG PAYMENT ANYMORE 
    # creating the backlog payment 
    # member.backlog_payments_for_group_loan(group_loan).where(:is_cleared => false ).order("created_at ASC").limit( number_of_backlogs ).each do |x|
    #    x.is_cleared  = true 
    #    x.clearance_period = BACKLOG_CLEARANCE_PERIOD[:in_grace_period]
    #    x.backlog_cleared_declarator_id = employee.id 
    #    x.transaction_activity_id_for_backlog_clearance = transaction_activity.id
    #    x.save
    # end 
    
    
    if transaction_activity.nil?
      return nil
    else
      if revision_transaction == false 
        MemberPaymentHistory.create_grace_payment_history_entry(
          employee,  # creator 
          nil,  # period object 
          group_loan,  # the loan product
          LOAN_PRODUCT[:group_loan],
          member, # the member who paid 
          cash,  #  the cash passed
          savings_withdrawal, # savings withdrawal used
          nil, # in grace payment, number of weeks is nil 
          nil, # in grace payment, number of weeks is nil 
          transaction_activity.id, # the self 
          REVISION_CODE[:original_grace_payment],
          PAYMENT_PHASE[:grace_payment] 
        ) 
      end
    end
    
    
    
    
  
    transaction_activity.create_grace_period_payment_transaction_entries(cash, employee, member) 

    if savings_withdrawal > zero_value 
      # transaction_activity.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      transaction_activity.create_grace_payment_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
    end
    
    if extra_savings > zero_value
      # transaction_activity.create_extra_savings_entries(extra_savings, employee, member )
      transaction_activity.create_extra_savings_from_grace_payment_entries(extra_savings, employee, member )
    end
    
    #  update the default_payment.unpaid_grace_period_amount 
    if total_amount_paid < total_payable  
      default_payment.update_paid_grace_period_amount( total_amount_paid  )
    else
      default_payment.update_paid_grace_period_amount( total_payable  )
    end
    
    # update the default loan resolution amount 
    group_loan.update_default_payment_in_grace_period
    
    
    
    return transaction_activity
  end
  
  def TransactionActivity.update_generic_grace_period_payment(
          group_loan_membership,
          employee,
          cash,
          savings_withdrawal )
  
    return nil if group_loan_membership.nil? or employee.nil? or 
            cash.nil?  or savings_withdrawal.nil? 
            
          
        
    pending_approval_grace_payment = group_loan_membership.unapproved_grace_period_payment
    
    if (pending_approval_grace_payment).nil?
      return nil
    end
    
    
    default_payment = group_loan_membership.default_payment 
    group_loan =  group_loan_membership.group_loan
    member = group_loan_membership.member  
    saving_related_transaction_entry_code_list = [
      
      TRANSACTION_ENTRY_CODE[:grace_period_payment_soft_savings_withdrawal] ,
      TRANSACTION_ENTRY_CODE[:grace_period_payment_extra_savings] 
     ]
    
   
    pending_approval_grace_payment.transaction_entries.where( 
                      :transaction_entry_code => saving_related_transaction_entry_code_list).each do |te|
      te.revert_and_delete 
    end 
    
    pending_approval_grace_payment.transaction_entries.where( 
                      :transaction_entry_code =>TRANSACTION_ENTRY_CODE[:grace_period_payment] ).each do |te|
      te.is_deleted = true
      te.deleted_datetime = DateTime.now 
      te.save
    end
    
    
=begin
    total_payable = default_payment.unpaid_grace_period_amount
    total_payable = default_payment.unpaid_grace_period_amount
    total_amount_paid = cash + savings_withdrawal
    
    
    if total_amount_paid < total_payable  
      default_payment.update_paid_grace_period_amount( total_amount_paid  )
    else
      default_payment.update_paid_grace_period_amount( total_payable  )
    end
=end

    pending_approval_grace_payment.is_deleted = true
    pending_approval_grace_payment.save 
    zero_value = BigDecimal('0')
    past_savings_withdrawal = pending_approval_grace_payment.grace_payment_savings_withdrawal_amount 
    past_cash = pending_approval_grace_payment.total_transaction_amount
    past_extra_savings = pending_approval_grace_payment.grace_payment_extra_savings_amount
    
    deduction_paid_grace_period_amount = BigDecimal('0')
    if past_extra_savings > zero_value 
      deduction_paid_grace_period_amount = past_savings_withdrawal + past_cash - past_extra_savings
    else
      deduction_paid_grace_period_amount = past_savings_withdrawal + past_cash
    end
    
    
    
    
    default_payment.cancel_update_paid_grace_period_amount( deduction_paid_grace_period_amount )
    group_loan_membership.reload 
    # =>                -> on the default_payment.update_paid_grace_period_amount
    
    # try to create the transaction
    # rollback if it is nil 
    
    transaction_activity = TransactionActivity.create_generic_grace_period_payment(
            group_loan_membership,
            employee,
            cash,
            savings_withdrawal,
            true )
    

    if transaction_activity.nil?
      raise ActiveRecord::Rollback, "Call tech support!"  # <<< THIS IS THE SHITE!!!! 
      return nil 
    end
    
    
    MemberPaymentHistory.create_grace_payment_history_entry(
      employee,  # creator 
      nil,  # period object 
      group_loan,  # the loan product
      LOAN_PRODUCT[:group_loan],
      member, # the member who paid 
      cash,  #  the cash passed
      savings_withdrawal, # savings withdrawal used
      nil, # in grace payment, number of weeks is nil 
      nil, # in grace payment, number of weeks is nil 
      transaction_activity.id, # the self 
      REVISION_CODE[:update_grace_payment],
      PAYMENT_PHASE[:grace_payment] 
    )

    return transaction_activity 
  
  end
  
  
  
  
  
=begin
########################################################## 
############################# UTILITY METHOD
##########################################################
=end
  def single_extra_savings_weekly_payment?
    self.number_of_weekly_payments_paid ==1 && 
    self.transaction_entries.where(:transaction_entry_code=> TRANSACTION_ENTRY_CODE[:extra_weekly_saving]).count != 0 
  end
  
  
  def multiple_structured_weeks_weekly_payment?(weekly_task)
    # if there is backlog, return true
    # if there is savings withdrawal return true 
    
    # if it is just single week extra savings, return fasle
    return false if self.single_extra_savings_weekly_payment? 
    return false if self.only_savings_weekly_payment? 
    
    return true 
  end
  
  def basic_single_week_extra_savings_weekly_payment?(weekly_task)
    if not self.single_extra_savings_weekly_payment?
      return false 
    end
    
    associated_member_payment = MemberPayment.where(:transaction_activity_id => self.id ).first
    if  associated_member_payment.nil?
      return false
    end
    
    # transaction activity is only used to pay for that week payment 
    if weekly_task.week_number == associated_member_payment.week_number 
      return true
    else
      return false
    end
  end
  
  
  def only_savings_weekly_payment?
    transaction_code_regex = /^777(1|0)(1|0)(1|0)(0|1|2)(0|1|2)/
    
    cash = $1 
    savings_withdrawal = $2 
    extra_savings = $3
    number_of_weeks = $4
    number_of_backlogs  = $5 
    
    if cash == '1' and 
        extra_savings == '1' and 
        savings_withdrawal == '0' and 
        number_of_weeks == '0' and 
        number_of_backlogs == '0'
      return true
    end
    
    
    
    return false
  end
  
  def single_week_extra_savings_weekly_payment?
    # has multiple weeks
    # or has backlog payment
    # or has savings withdrawal 
    transaction_code_regex = /^777(1|0)(1|0)(1|0)(0|1|2)(0|1|2)/
    
    cash = $1 
    savings_withdrawal = $2 
    extra_savings = $3
    number_of_weeks = $4
    number_of_backlogs  = $5 
    
    if cash == '1' and 
        savings_withdrawal == '0' and 
        number_of_weeks == '1' and 
        number_of_backlogs == '0'
      return true
    end 
    
    return false  
  end
  
  def TransactionActivity.resolve_transaction_case( cash, savings_withdrawal, extra_savings,
                          number_of_weeks, number_of_backlogs)
                          
    prependix= "777"
    content = "" 
    zero_value = BigDecimal("0")
    
    # 77710010
    if cash > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if savings_withdrawal > zero_value
      content << 1.to_s
    else
      content << 0.to_s
    end
    
    if extra_savings > zero_value
      content << 1.to_s 
    else
      content << 0.to_s 
    end
    
    if number_of_weeks == 0 
      content << 0.to_s 
    elsif number_of_weeks == 1 
      content << 1.to_s 
    elsif number_of_weeks >  1 
      content << 2.to_s 
    end
    
    if number_of_backlogs == 0 
      content << 0.to_s 
    elsif number_of_backlogs == 1
      content << 1.to_s 
    elsif number_of_backlogs > 1 
      content << 2.to_s 
    end
    
    return ( prependix + content ) .to_i 
  end
  
  
  def TransactionActivity.create_basic_weekly_payment(member,weekly_task, employee )
    if not self.is_employee_role_correct_and_weekly_task_finalized?( weekly_task, employee )
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
     
    
    new_hash = {}
    new_hash[:total_transaction_amount]  = group_loan_product.total_weekly_payment
    new_hash[:transaction_case] = TRANSACTION_CASE[:weekly_payment_basic]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:transaction_action_type] = TRANSACTION_ACTION_TYPE[:inward]
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = group_loan_membership.group_loan_id
    
    transaction_activity = TransactionActivity.create new_hash 
    transaction_activity.create_basic_payment_entries(group_loan_product, employee, member )
    
    weekly_task.create_basic_weekly_payment( member, transaction_activity, group_loan_product.total_weekly_payment, false)
    
    
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
   
=begin
  For backlog payments
=end

  def TransactionActivity.create_backlog_payments(member,group_loan, employee,
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
   
   new_hash[:creator_id] = employee.id 
   new_hash[:office_id] = employee.active_job_attachment.office.id
   new_hash[:member_id] = member.id
   new_hash[:loan_type] = LOAN_TYPE[:group_loan]
   new_hash[:loan_id] = group_loan_membership.group_loan_id
   
   transaction_activity = TransactionActivity.create new_hash 
   
   transaction_activity.create_backlog_payment_entries(
             cash,
             savings_withdrawal,
             number_of_weeks, 
             group_loan_product,
             employee,
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
     x.backlog_cleared_declarator_id = employee.id 
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
  
  def approve_backlog_payments(employee)
    if  not employee.has_role?(:cashier, employee.get_active_job_attachment)
      return nil
    end
    
    self.backlog_payments.each do |backlog_payment|
      backlog_payment.create_cashier_cash_approval(employee)
    end 
  end
  
  
  
  
  
  
=begin
  DEFAULT_PAYMENT_RESOLUTION
  new method 
=end 
  def savings_default_payment_deduction
    # self.transaction_entries.where(:)
  end
  
  def TransactionActivity.create_default_payment_resolution( default_payment,  employee  ) 
    # flow: field worker propose default payment resolution : standard or custom (if custom, use the number as well ) 
    
    # then, the cashier approves
    
    if not employee.has_role?(:cashier, employee.active_job_attachment)
      puts "666 no role"
      return nil 
    end
    
    glm = default_payment.group_loan_membership 
    member = glm.member 
    
    
    amount_to_be_paid = default_payment.amount_paid

    
    puts "8821 amount to be paid: #{amount_to_be_paid}"
    # deduce transaction_case 
    
    if default_payment.is_actual_non_defaultee? == true and amount_to_be_paid > member.saving_book.total_compulsory_savings
      puts "666 total compulsory savings: #{member.saving_book.total_compulsory_savings.to_s}"
      puts "666 to be paid: #{amount_to_be_paid.to_s}"
      puts "666 not enough money, boom boom is deafultee = false"
      
      return nil
    end
    
    if default_payment.is_actual_non_defaultee? == false  and  amount_to_be_paid > member.saving_book.total 
      puts "777 total  savings: #{member.saving_book.total.to_s}"
      puts "777 to be paid: #{amount_to_be_paid.to_s}"
      puts "777 not enough money, is deafultee = false"
      puts "777 compulsory savings to be deducted = #{default_payment.amount_of_compulsory_savings_deduction.to_s}"
      puts "777 voluntary savings to be deducted = #{default_payment.amount_of_extra_savings_deduction.to_s}"
      return nil
    end
 
    
    
    
    transaction_case = ""
    
    if default_payment.custom_amount.nil?   
      transaction_case = TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_standard_amount]
    else
      transaction_case = TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_custom_amount]
    end
    
    # through compulsory savings deduction. No cash payment 
    new_hash = {}
    new_hash[:total_transaction_amount] = BigDecimal("0") #no hard money flowing 
    new_hash[:transaction_case]  = transaction_case #  TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_standard_amount]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = glm.group_loan_id
    new_hash[:is_approved] = true
    new_hash[:approver_id] = employee.id

    transaction_activity = TransactionActivity.create new_hash
    
    
    default_payment.set_default_amount_deducted(amount_to_be_paid,  transaction_activity)
    # member.deduct_savings( default_payment.amount_paid, SAVING_ENTRY_CODE[:soft_withdraw_for_default_payment] , transaction_entry )
    # the savings deduction is done in the transaction entry
    # transaction_activity.create_auto_default_payment_resolution_entries( default_payment) 
    transaction_activity.create_default_payment_resolution_transaction_entries(default_payment , member)
    return transaction_activity
  end
  
  def TransactionActivity.create_custom_default_payment_resolution( default_payment,  employee  ) 
    # flow: field worker propose default payment resolution : standard or custom (if custom, use the number as well ) 
    
    # then, the cashier approves
    
    if not employee.has_role?(:cashier, employee.active_job_attachment)
      puts "666 no role"
      return nil 
    end
    
    glm = default_payment.group_loan_membership 
    member = glm.member 
    
    
    amount_to_be_paid = default_payment.custom_amount

    
    puts "8821 amount to be paid: #{amount_to_be_paid}"
    # deduce transaction_case 
    
    # if default_payment.is_actual_non_defaultee? == true and amount_to_be_paid > member.saving_book.total_compulsory_savings
    #   puts "666 total compulsory savings: #{member.saving_book.total_compulsory_savings.to_s}"
    #   puts "666 to be paid: #{amount_to_be_paid.to_s}"
    #   puts "666 not enough money, boom boom is deafultee = false"
    #   
    #   return nil
    # end
    # 
    # if default_payment.is_actual_non_defaultee? == false and  amount_to_be_paid > member.saving_book.total 
    #   puts "777 total  savings: #{member.saving_book.total.to_s}"
    #   puts "777 to be paid: #{amount_to_be_paid.to_s}"
    #   puts "777 not enough money, is deafultee = false"
    #   puts "777 compulsory savings to be deducted = #{default_payment.amount_of_compulsory_savings_deduction.to_s}"
    #   puts "777 voluntary savings to be deducted = #{default_payment.amount_of_extra_savings_deduction.to_s}"
    #   return nil
    # end
    
    if amount_to_be_paid > member.saving_book.total_compulsory_savings 
      return nil
    end
 
    
     
    transaction_case = TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_custom_amount]
    
    
    # through compulsory savings deduction. No cash payment 
    new_hash = {}
    new_hash[:total_transaction_amount] = BigDecimal("0") #no hard money flowing 
    new_hash[:transaction_case]  = transaction_case #  TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_standard_amount]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = glm.group_loan_id
    new_hash[:is_approved] = true
    new_hash[:approver_id] = employee.id

    transaction_activity = TransactionActivity.create new_hash
    
    
    default_payment.set_default_amount_deducted(amount_to_be_paid,  transaction_activity)
    # member.deduct_savings( default_payment.amount_paid, SAVING_ENTRY_CODE[:soft_withdraw_for_default_payment] , transaction_entry )
    # the savings deduction is done in the transaction entry
    # transaction_activity.create_auto_default_payment_resolution_entries( default_payment) 
    transaction_activity.create_custom_default_payment_resolution_transaction_entries(default_payment , member)
    return transaction_activity
  end
  
  
  
=begin
  For the default loan resolution
=end
  def TransactionActivity.port_compulsory_savings_to_extra_savings(glm, employee)
    if not employee.has_role?(:branch_manager, employee.active_job_attachment) 
      return nil
    end
    
    member = glm.member
    group_loan = glm.group_loan 
    
    
    new_hash = {}
    new_hash[:total_transaction_amount] = BigDecimal("0") #no hard money flowing 
    new_hash[:transaction_case]  = TRANSACTION_CASE[:port_compulsory_savings_during_group_loan_closing]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] = glm.group_loan_id
    new_hash[:is_approved] = true
    new_hash[:approver_id] = employee.id

    transaction_activity = TransactionActivity.create new_hash
    
    default_payment = glm.default_payment 
    # transaction_activity.create_default_payment_savings_withdrawal_transaction_entry(default_payment.amount_paid , member)
    
    transaction_activity.create_port_compulsory_savings_on_group_loan_closing_transaction_entry( member.saving_book.total_compulsory_savings , member )
    return transaction_activity
  end
  

=begin
  GROUP LOAN  SAVINGS WITHDRAWAL (not the disbursement)
=end

  def TransactionActivity.create_cash_savings_withdrawal( amount, employee, member ) 
    return nil if amount.nil? or employee.nil? or member.nil? 
    
    return nil if not GroupLoanMembership.can_perform_cash_savings_withdrawal?(member)
    return nil if TransactionActivity.where(:member_id => member.id, :is_approved => false ).count != 0 
    return nil if not employee.has_role?(:cashier, employee.active_job_attachment)
    return nil if amount < 0 
    return nil if amount > member.saving_book.total_extra_savings 
    
    
    new_hash = {}
    new_hash[:total_transaction_amount] = amount # hard money flowing 
    new_hash[:transaction_case]  = TRANSACTION_CASE[:cash_savings_withdrawal]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = nil
    new_hash[:loan_id] =  nil 
    new_hash[:is_approved] =  true 
    new_hash[:approver_id] =  employee.id 

    transaction_activity = TransactionActivity.create new_hash
    
    transaction_activity.create_cash_savings_withdrawal_entry( amount, member)
  end
 

=begin
  GROUP LOAN  SAVINGS DISBURSEMENT
=end

# execute means: giving the total savings from group loan to the field worker
# passing it out to the corresponding member 
  def TransactionActivity.execute_group_loan_savings_disbursement( glm, employee ) 
    member  = glm.member
    amount = glm.member.saving_book.total
    
    new_hash = {}
    new_hash[:total_transaction_amount] = amount # hard money flowing 
    new_hash[:transaction_case]  = TRANSACTION_CASE[:group_loan_savings_disbursement]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] =  glm.group_loan_id 
    new_hash[:is_approved] =  true 
    new_hash[:approver_id] =  employee.id 

    transaction_activity = TransactionActivity.create new_hash

    transaction_activity.create_savings_disbursement_entry( amount, member)
  end
  
# finalizing: on savings disbursement, field worker will ask whether the member wants to 
# save the $$$.. re-saving the disbursed $$ is handled by this method
  def TransactionActivity.finalize_group_loan_savings_disbursement( glm, employee ) 
    member  = glm.member
    amount = glm.saved_disbursed_savings
    
    new_hash = {}
    new_hash[:total_transaction_amount] = glm.saved_disbursed_savings # hard money flowing 
    new_hash[:transaction_case]  = TRANSACTION_CASE[:save_group_loan_disbursed_savings]
    new_hash[:creator_id] = employee.id 
    new_hash[:office_id] = employee.active_job_attachment.office.id
    new_hash[:member_id] = member.id
    new_hash[:loan_type] = LOAN_TYPE[:group_loan]
    new_hash[:loan_id] =  glm.group_loan_id 
    new_hash[:is_approved] =  true 
    new_hash[:approver_id] =  employee.id 

    transaction_activity = TransactionActivity.create new_hash
    
    puts "glm.saved_disbursed_savings: #{glm.saved_disbursed_savings}"

    transaction_activity.create_save_disbursed_savings_entry( amount, member)
  end
  
  
  
############################################
###############
############### => Transaction entry creation 
###############
#############################################

  def create_cash_savings_withdrawal_entry( amount, member)
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:hard_saving_withdrawal] , 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
         
    member.deduct_extra_savings(amount, SAVING_ENTRY_CODE[:deduct_extra_savings_for_cash_savings_withdrawal] , transaction_entry  ) 
  end
  
  def create_savings_disbursement_entry( amount, member)
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:group_loan_savings_disbursement] , 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
         
    member.deduct_extra_savings(amount, SAVING_ENTRY_CODE[:group_loan_savings_disbursement] , transaction_entry  ) 
  end
  
  def create_save_disbursed_savings_entry( amount, member)
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:save_group_loan_disbursed_savings] , 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
         
    puts "The amount from transaction_activity#create_save_disbursed_savings_entry: #{amount}"
    member.add_savings_account(amount, SAVING_ENTRY_CODE[:save_group_loan_disbursed_savings] , transaction_entry  )
  end

=begin
  Group Loan, default loan resolution
=end

  def create_default_payment_resolution_transaction_entries( default_payment, member)
    member = default_payment.group_loan_membership.member
    compulsory_savings = member.saving_book.total_compulsory_savings
    extra_savings = member.saving_book.total_extra_savings 
    total_savings = member.saving_book.total 
    amount_to_be_paid = default_payment.amount_paid 

    # create_default_payment_transaction_entry( TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction], default_payment.amount_of_compulsory_savings_deduction)
    # create_default_payment_transaction_entry( TRANSACTION_ENTRY_CODE[:default_payment_extra_savings_deduction], default_payment.amount_of_extra_savings_deduction)
    # 
    if amount_to_be_paid <= compulsory_savings 
      create_default_payment_transaction_entry( TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction], amount_to_be_paid)
    else
      if default_payment.is_defaultee == true 
        create_default_payment_transaction_entry( TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction], compulsory_savings)
        excess_default = amount_to_be_paid - compulsory_savings
        
        if excess_default > extra_savings 
          create_default_payment_transaction_entry(  TRANSACTION_ENTRY_CODE[:default_payment_extra_savings_deduction], extra_savings)
        else
          create_default_payment_transaction_entry(   TRANSACTION_ENTRY_CODE[:default_payment_extra_savings_deduction], excess_default)
        end
      else
        create_default_payment_transaction_entry(  TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction], compulsory_savings)
      end
    end
  end
  
  def create_custom_default_payment_resolution_transaction_entries( default_payment, member)
    member = default_payment.group_loan_membership.member
    compulsory_savings = member.saving_book.total_compulsory_savings
    extra_savings = member.saving_book.total_extra_savings 
    total_savings = member.saving_book.total 
    amount_to_be_paid = default_payment.amount_paid  

     
    create_default_payment_transaction_entry( TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction], amount_to_be_paid)
  end
    
    

  
=begin
  create transaction entry for default loan resolution payment
=end

  def create_default_payment_transaction_entry(transaction_entry_code, amount)
    transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code =>  transaction_entry_code , 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
                      
                      
    if transaction_entry_code == TRANSACTION_ENTRY_CODE[:default_payment_compulsory_savings_deduction]
      member.deduct_compulsory_savings( amount, SAVING_ENTRY_CODE[:deduct_compulsory_savings_for_default_payment] , transaction_entry  ) 
    elsif transaction_entry_code == TRANSACTION_ENTRY_CODE[:default_payment_extra_savings_deduction]
      member.deduct_extra_savings(amount, SAVING_ENTRY_CODE[:deduct_extra_savings_for_default_payment] , transaction_entry  ) 
    end  
  end
  
  
  def create_port_compulsory_savings_on_group_loan_closing_transaction_entry(amount, member ) 
    # take it out from compulsory savings
    transaction_entry  = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:port_remaining_compulsory_savings_on_group_loan_close], 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
    member.deduct_compulsory_savings( amount, SAVING_ENTRY_CODE[:deduct_compulsory_savings_to_be_ported_to_extra_savings] , transaction_entry )
    
    #  pull it into the voluntary savings 
    transaction_entry  = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:port_remaining_compulsory_savings_on_group_loan_close], 
                      :amount => amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
    member.add_extra_savings( amount, SAVING_ENTRY_CODE[:add_extra_savings_from_compulsory_savings_deduction] , transaction_entry )
  end
  
  def create_default_payment_savings_withdrawal_transaction_entry(savings_withdrawal_amount, member)
    transaction_entry  = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:default_loan_resolution_compulsory_savings_withdrawal], 
                      :amount => savings_withdrawal_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
    # member.add_savings(savings_amount, SAVING_ENTRY_CODE[:no_weekly_payment_only_savings], savings_only_transaction_entry) 
    member.deduct_compulsory_savings( savings_withdrawal_amount, SAVING_ENTRY_CODE[:soft_withdraw_for_default_payment] , transaction_entry )
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


  def create_independent_savings_entry(savings_amount, employee, member )
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    savings_only_transaction_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:independent_savings_deposit], 
                      :amount => savings_amount  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                    
    member.add_extra_savings(savings_amount, SAVING_ENTRY_CODE[:independent_savings_deposit], savings_only_transaction_entry) 

  end

  def create_only_savings_payment_entry(savings_amount, employee, member )
    cashflow_book = employee.active_job_attachment.office.cashflow_book
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
  
  
  def create_grace_period_payment_transaction_entries(cash, employee, member)
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment], 
                      :amount => cash ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )                 
  end
  
  
  def create_grace_period_backlog_payment_transaction_entries(group_loan_product, employee, member)
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_principal], 
                      :amount => group_loan_product.principal  ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_interest], 
                      :amount => group_loan_product.interest,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
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
  
  def create_extra_savings_entries( balance , employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:extra_weekly_saving], 
                      :amount => balance ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_extra_savings(balance, SAVING_ENTRY_CODE[:weekly_saving_extra_from_basic_payment], saving_entry) 
  end
  
  def create_extra_savings_entries_from_only_savings_independent_payment( balance , employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:only_savings_independent_payment], 
                      :amount => balance ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_extra_savings(balance, SAVING_ENTRY_CODE[:only_savings_independent_payment], saving_entry)
  end
  
  def create_extra_savings_from_grace_payment_entries( balance , employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_extra_savings], 
                      :amount => balance ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:inward]
                      )
                      
    member.add_extra_savings(balance, SAVING_ENTRY_CODE[:extra_savings_from_grace_payment], saving_entry)
  end
  
  def create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:soft_savings_withdrawal], 
                      :amount => savings_withdrawal ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
                      
    # update member savings , add saving entries 
    member.deduct_extra_savings( savings_withdrawal, SAVING_ENTRY_CODE[:soft_withdraw_to_pay_basic_weekly_payment],saving_entry )
  end
  
  def create_grace_payment_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    saving_entry = self.transaction_entries.create( 
                      :transaction_entry_code => TRANSACTION_ENTRY_CODE[:grace_period_payment_soft_savings_withdrawal], 
                      :amount => savings_withdrawal ,
                      :transaction_entry_action_type => TRANSACTION_ENTRY_ACTION_TYPE[:outward]
                      )
                      
    # update member savings , add saving entries 
    member.deduct_extra_savings( savings_withdrawal, SAVING_ENTRY_CODE[:soft_withdraw_to_pay_grace_payment],saving_entry )
  end
  
  def create_structured_multi_payment_entries(cash, savings_withdrawal, number_of_weeks, 
            group_loan_product, weekly_task , employee , member)
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    balance = cash + savings_withdrawal- (group_loan_product.total_weekly_payment * number_of_weeks)
    
    if self.transaction_case == TRANSACTION_CASE[:weekly_payment_basic]
     self.create_basic_payment_entries(group_loan_product, employee, member) 
     
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks]
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
     
    elsif self.transaction_case ==  TRANSACTION_CASE[:weekly_payment_single_week_extra_savings]
     self.create_basic_payment_entries(group_loan_product, employee, member)
     self.create_extra_savings_entries( balance , employee, member )
    
    elsif self.transaction_case ==  TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_extra_savings]
      self.create_extra_savings_entries( balance , employee , member )
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      self.create_basic_payment_entries(group_loan_product, employee, member ) 
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_single_week_structured_with_soft_savings_withdrawal_extra_savings]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      self.create_basic_payment_entries(group_loan_product, employee, member ) 
      self.create_extra_savings_entries( balance , employee, member )
        
    elsif self.transaction_case == TRANSACTION_CASE[:weekly_payment_structured_multiple_weeks_with_soft_savings_withdrawal_extra_savings] 
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      self.create_extra_savings_entries( balance , employee, member )
    
    end
  end
  
  def create_backlog_payment_entries( cash, savings_withdrawal,  number_of_weeks,  group_loan_product,
      employee, member)
    # start 
    cashflow_book = employee.active_job_attachment.office.cashflow_book
    balance = cash + savings_withdrawal- (group_loan_product.total_weekly_payment * number_of_weeks)
    
    if self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_exact_amount]
     self.create_basic_payment_entries(group_loan_product, employee, member) 
     
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_exact_amount]
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
     
    elsif self.transaction_case ==  TRANSACTION_CASE[:single_backlog_payment_extra_savings]
     self.create_basic_payment_entries(group_loan_product, employee, member)
     self.create_extra_savings_entries( balance , employee, member )
    
    elsif self.transaction_case ==  TRANSACTION_CASE[:multiple_backlog_payment_extra_savings]
      self.create_extra_savings_entries( balance , employee , member )
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      self.create_basic_payment_entries(group_loan_product, employee, member ) 
      
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      
    elsif self.transaction_case == TRANSACTION_CASE[:single_backlog_payment_soft_savings_withdrawal_extra_savings]
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      self.create_basic_payment_entries(group_loan_product, employee, member ) 
      self.create_extra_savings_entries( balance , employee, member )
        
    elsif self.transaction_case == TRANSACTION_CASE[:multiple_backlog_payment_soft_savings_withdrawal_extra_savings] 
      self.create_soft_savings_withdrawal_entries( savings_withdrawal, employee , member)
      (1..number_of_weeks).each do |week_number|
        self.create_basic_payment_entries(group_loan_product, employee, member) 
      end
      self.create_extra_savings_entries( balance , employee, member )
    
    end
    
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

