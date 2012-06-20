class TransactionActivitiesController < ApplicationController
  
=begin
  Group Loan Initialization 
=end
  def create_transaction_activity_for_setup_payment
    admin_fee = BigDecimal.new( params[:admin_fee] )
    initial_savings = BigDecimal.new( params[:initial_savings] )
    deposit = BigDecimal.new( params[:deposit] )
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:group_loan_membership_id] )

    @transaction_activity = TransactionActivity.create_setup_payment( admin_fee, initial_savings,
              deposit, current_user, @group_loan_membership )
  end
  
  
  def execute_loan_disbursement
    @group_loan_membership = GroupLoanMembership.find_by_id( params[:entity_id] )
    @transaction_activity = TransactionActivity.execute_loan_disbursement( @group_loan_membership , current_user)
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
    
    @transaction_activity = TransactionActivity.create_generic_weekly_payment(
            @group_loan_membership,
            current_user,
            @group_loan_membership.group_loan_product.total_weekly_payment,
            BigDecimal("0"), 
            1,
            0)
    # @transaction_activity = TransactionActivity.create_basic_weekly_payment(
    #   @member,
    #   @weekly_task,
    #   current_user
    # )
  end
  
  def create_savings_only_as_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    @savings_only = BigDecimal.new( params[:os_cash_amount])
    
    @transaction_activity = TransactionActivity.create_savings_only_weekly_payment(
      @member,
      @weekly_task,
      @savings_only,
      current_user
    )
    
    
  end
  
  def create_structured_multiple_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]

    cash = BigDecimal.new( params[:smf_cash] )
    savings_withdrawal = BigDecimal.new( params[:smf_savings_withdrawal] )
    number_of_weeks = params[:smf_weeks].to_i

    @transaction_activity = TransactionActivity.create_structured_multiple_payment(
      @member,
      @weekly_task,
      current_user,
      cash,
      savings_withdrawal,
      number_of_weeks
    )
  end
  

  def create_no_weekly_payment
    @weekly_task = WeeklyTask.find_by_id( params[:weekly_task_id] )
    @member  = Member.find_by_id params[:member_id]
    
    # weekly_task.has_paid_weekly_payment?(member)  << filter to prevent double member payment
    @member_payment = @weekly_task.create_weekly_payment_declared_as_no_payment(@member)
  end
  
  def create_backlog_payment
    @member = Member.find params[:member_id]
    @group_loan = GroupLoan.find params[:group_loan_id]

    cash = BigDecimal.new( params[:bmf_cash] )
    savings_withdrawal = BigDecimal.new( params[:bmf_savings_withdrawal] )
    number_of_weeks = params[:bmf_weeks].to_i

    @transaction_activity = TransactionActivity.create_backlog_payments(
      @member,
      @group_loan,
      current_user,
      cash,
      savings_withdrawal,
      number_of_weeks
    )
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
    @transaction_activity = TransactionActivity.create_generic_grace_period_payment(
            @group_loan_membership,
            current_user,
            cash,
            savings_withdrawal,  
            number_of_backlogs)
  end
  
=begin
  GRACE PERIOD PAYMENT APPROVAL
=end
  def select_pending_grace_period_payment_to_be_approved
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    
    @grace_period_transactions = @group_loan.grace_period_transactions
    # @pending_approval_transactions = @group_loan.pending_approval_grace_period_transactions
    
    
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_for_grace_period_payment_approval_url'
    set_breadcrumb_for @group_loan, 'select_pending_grace_period_payment_to_be_approved_url' + "(#{@group_loan.id})", 
                "Grace Period Payment Approval"
  end
  
  def execute_backlog_payment_transaction_approval_by_cashier
    @transaction_activity  = TransactionActivity.find_by_id params[:entity_id]
    
    @transaction_activity.approve_grace_period_payment( current_user ) 
    
    @transaction_activity.reload 
  end
  
=begin
  Default loan resolution 
=end
  def pay_default_loan_resolution_by_structured_payment
    @default_payment = DefaultPayment.find_by_id(params[:default_payment_id])
    
    @transaction_activity = TransactionActivity.create_default_loan_resolution_payment(   @default_payment,
                                                          current_user,
                                                          cash, 
                                                          savings_withdrawal)
  end
 
  
  
end
