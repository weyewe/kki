class GroupLoanSubcriptionsController < ApplicationController
  def new
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @group_loan_members = @group_loan.members
    # @group_loan_products_used = @group_loan.all_group_loan_products_used
    @group_loan_products = @office.group_loan_products
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_group_loan_product_url'
    set_breadcrumb_for @group_loan, 'new_group_loan_group_loan_subcription_url' + "(#{@group_loan.id})", 
                 "#{t 'process.assign_product'}"
                 
  end
  
  
  def create
    @membership_provider = params[:membership_provider].to_i
    @membership_consumer = params[:membership_consumer].to_i
    
    
    @group_loan_subcription = GroupLoanSubcription.create_or_change(@membership_provider,@membership_consumer  )
    @group_loan_membership = @group_loan_subcription.group_loan_membership
    @group_loan = @group_loan_membership.group_loan
    @member = @group_loan_membership.member
    
  end
  
  
end
