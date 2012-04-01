class TransactionActivitiesController < ApplicationController
  
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
    @transaction_activity = TransactionActivity.create_basic_weekly_payment(
      @member,
      @weekly_task,
      current_user
    )
  end
  
  def create_special_weekly_payment
  end
  
  def create_savings_only_as_weekly_payment
  end
  
  def create_backlog_payment
  end
  
  
end
