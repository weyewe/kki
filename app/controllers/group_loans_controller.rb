class GroupLoansController < ApplicationController
  def new
    setup_group_loan
    @new_group_loan = GroupLoan.new 
  end
  
  def create
    setup_group_loan
    @new_group_loan = GroupLoan.new(params[:group_loan])
    @new_group_loan.creator_id  = current_user.id 
    @new_group_loan.office_id = @office.id 
    
    if @new_group_loan.save
      flash[:notice] = "The new member has been created." + 
                    " To see the list, click <a href='#data_list'>here</a>."
      redirect_to new_group_loan_url 
    else
      flash[:error] = "Hey, do something better"
      render :file => "group_loans/new"
    end
  end
  
=begin
  To select group_loan in which member is gonna be assigned 
  role = LOAN_OFFICER
=end
  
  def select_group_loan_to_assign_member
    setup_select_group_loan
  end
  
  def select_group_loan_to_group_loan_product
    setup_select_group_loan
  end
  
  
  def select_group_loan_for_finalization
    setup_select_group_loan
  end
  
  def execute_propose_finalization
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan.execute_propose_finalization( current_user )
    @action_executor = params[:action_executor]
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js { render :file => "group_loans/respond_to_finalization_proposal.js.erb" }
    end
  end
  
  protected
  def setup_group_loan
    @office = current_user.active_job_attachment.office
    @active_group_loans = @office.active_group_loans
    @all_communes = @office.all_communes_under_management
  end
  
  def setup_select_group_loan
    @office = current_user.active_job_attachment.office
    @active_group_loans = @office.active_group_loans
  end
end
