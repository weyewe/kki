class MemberPaymentsController < ApplicationController
  def create_basic_payment
    @weekly_task  = WeeklyTask.find_by_id params[:weekly_task_id]
    @member = Member.find_by_id params[:entity_id]
    @group_loan_membership = GroupLoanMembership.find(:first, :conditions => {
      :member_id => @member.id, 
      :group_loan_id => @weekly_task.group_loan.id 
    })
    @weekly_task.create_basic_payment( @member, current_user )
  end
  
  
end
