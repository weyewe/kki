class TransactionActivitiesController < ApplicationController
  
=begin
  Group Loan Initialization 
=end
  def create_transaction_activity_for_setup_payment
    admin_fee = BigDecimal.new( params[:admin_fee] )
    initial_savings = BigDecimal.new( params[:initial_savings] )
    deposit = BigDecimal.new( params[:deposit] )
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:group_loan_membership_id] )
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_setup_payment( admin_fee, initial_savings,
                  deposit, current_user, @group_loan_membership )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
  end
  
  
  def execute_loan_disbursement
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:entity_id] )
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.execute_loan_disbursement( @group_loan_membership , current_user)
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
  end
  
  
=begin
  For the Member Payment in Weekly Group Loan
=end
  
  def create_basic_weekly_payment 
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id])
    @member = Member.find_by_id( params[:entity_id] )
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id,
      :group_loan_id => @weekly_task.group_loan.id 
    })
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task,
                @group_loan_membership,
                current_user,
                @group_loan_membership.group_loan_product.total_weekly_payment,
                BigDecimal("0"), 
                1,
                0)
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
  end
  
  def create_single_week_extra_savings_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @cash = BigDecimal(params[:ses_cash_amount])
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id,
      :group_loan_id => @weekly_task.group_loan.id 
    })
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_generic_weekly_payment(
                @weekly_task,
                @group_loan_membership,
                current_user,
                @cash,
                BigDecimal("0"), 
                1,
                0)
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end 
  end
  
  
  
  def create_savings_only_as_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @savings_only = BigDecimal.new( params[:os_cash_amount])
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_savings_only_weekly_payment(
          @member,
          @weekly_task,
          @savings_only,
          current_user
        )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
    
    
  end
  
  def create_structured_multiple_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @group_loan = @weekly_task.group_loan
    @group_loan_membership = @group_loan.get_membership_for_member( @member )
    
    cash = BigDecimal.new( params[:smf_cash] )
    savings_withdrawal = BigDecimal.new( params[:smf_savings_withdrawal] )
    number_of_weeks = params[:smf_weeks].to_i
    number_of_backlogs = params[:smf_backlogs].to_i
    
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_generic_weekly_payment(
        @weekly_task,
                @group_loan_membership,
                current_user,
                cash,
                savings_withdrawal,
                number_of_weeks,  
                number_of_backlogs  )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
            
  end
  

  def create_no_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    
    # weekly_task.has_paid_weekly_payment?(member)  << filter to prevent double member payment
    begin
      ActiveRecord::Base.transaction do
        @member_payment = @weekly_task.create_weekly_payment_declared_as_no_payment(@member)
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end 
  end
  
  def update_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @cash = BigDecimal(params[:ses_cash_amount])
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id,
      :group_loan_id => @weekly_task.group_loan.id 
    })
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.update_generic_weekly_payment(
                @weekly_task,
                @group_loan_membership,
                current_user,
                @cash,
                BigDecimal("0"), 
                1,
                0)
      end
    rescue ActiveRecord::Rollback
      
      @transaction_activity = nil 
      puts "Invalid data asshole!!!!"
    else
    end 
  end
  
  
  
  
  def create_backlog_payment
    @member = Member.find params[:member_id]
    @group_loan = GroupLoan.find params[:group_loan_id]

    cash = BigDecimal.new( params[:bmf_cash] )
    savings_withdrawal = BigDecimal.new( params[:bmf_savings_withdrawal] )
    number_of_weeks = params[:bmf_weeks].to_i

    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_backlog_payments(
          @member,
          @group_loan,
          current_user,
          cash,
          savings_withdrawal,
          number_of_weeks
        )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
  end
  
=begin
  MORE PAYMENT (WEEKLY_PAYMENT)
=end
  def create_only_extra_savings_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @group_loan_membership = @weekly_task.group_loan.get_membership_for_member( @member )
    @savings_only = BigDecimal.new( params[:oes_cash_amount])
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_weekly_extra_savings_only( 
          @weekly_task, 
          @group_loan_membership, 
          current_user, 
          @savings_only  )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
  end
  
=begin
  INDEPENDENT PAYMENT
=end

  def create_only_extra_savings_independent_payment
    @group_loan_membership = GroupLoanMembership.find_by_id params[:group_loan_membership_id]
    @group_loan = @group_loan_membership.group_loan
    @member = @group_loan_membership.member
    
    cash = BigDecimal.new( params[:oes_cash_amount] )
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity= TransactionActivity.create_only_extra_savings_independent_payment( 
          @group_loan_membership, 
          current_user, 
          cash  )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
  end
  
  
  def create_structured_multiple_independent_payment
  
    @group_loan_membership = GroupLoanMembership.find_by_id params[:group_loan_membership_id]
    @group_loan = @group_loan_membership.group_loan
    @member = @group_loan_membership.member 
    
    cash = BigDecimal.new( params[:smf_cash] )
    savings_withdrawal = BigDecimal.new( params[:smf_savings_withdrawal] )
    number_of_weeks = params[:smf_weeks].to_i
    number_of_backlogs = params[:smf_backlogs].to_i
    
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_generic_independent_payment(
                @group_loan_membership,
                current_user,
                cash, 
                savings_withdrawal,
                number_of_weeks,
                number_of_backlogs)
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
  end
  
  def approve_independent_payment_transaction_activity
    @transaction_activity = TransactionActivity.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == APPROVER_ROLE
      if @action_value == TRUE_CHECK
        
        begin
          ActiveRecord::Base.transaction do
            @transaction_activity.approve_payment(current_user)
          end
        rescue ActiveRecord::ActiveRecordError  
        else
        end
        
        
        
      elsif @action_value == FALSE_CHECK
        # @weekly_task.reject_weekly_payment_collection( current_user )
      end
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
=begin
  GRACE  PERIOD PAYMENT
=end

  def create_transcation_activity_for_grace_period_payment
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:group_loan_membership_id] )
    @member=  @group_loan_membership.member
    cash = BigDecimal(params[:smf_cash])
    number_of_backlogs = params[:smf_weeks].to_i
    savings_withdrawal = BigDecimal(params[:smf_savings_withdrawal])
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_generic_grace_period_payment(
                @group_loan_membership,
                current_user,
                cash,
                savings_withdrawal )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
  end
  
=begin
  GRACE PERIOD PAYMENT APPROVAL
=end
  def select_pending_grace_period_payment_to_be_approved
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    
    
    # @pending_approval_transactions = @group_loan.pending_approval_grace_period_transactions
    
    
    begin
      ActiveRecord::Base.transaction do
        @grace_period_transactions = @group_loan.pending_approval_grace_period_transactions
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_grace_period_payment_approval_url'
    set_breadcrumb_for @group_loan, 'select_pending_grace_period_payment_to_be_approved_url' + "(#{@group_loan.id})", 
                "#{t 'process.grace_period_payment_approval'}"
  end
  
  def execute_backlog_payment_transaction_approval_by_cashier
    @transaction_activity  = TransactionActivity.find_by_id params[:entity_id]
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity.approve_grace_period_payment( current_user ) 
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
    
    
    @transaction_activity.reload 
  end
  

=begin
  CASH SAVINGS WITHDRAWAL 
=end
  def execute_transaction_for_cash_savings_withdrawal
    @member = Member.find( params[:member_id])
    @amount = BigDecimal(params[:savings_withdrawal_amount])
    
    begin
      ActiveRecord::Base.transaction do
        @transaction_activity = TransactionActivity.create_cash_savings_withdrawal( @amount, current_user, @member )
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end
    
    
     
    if @transaction_activity.nil?
      redirect_to input_value_for_cash_savings_withdrawal_url(@member, :error => "There is error", :amount => @amount)
    else
      redirect_to input_value_for_cash_savings_withdrawal_url(@member, :amount => @amount)
    end
    
  end
 
  
  
end
