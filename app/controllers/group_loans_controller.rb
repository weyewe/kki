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
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action = params[:action].to_i  

    if @action_role == PROPOSER_ROLE 
      @group_loan.execute_propose_finalization( current_user )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
=begin
  Role == Branch Manager
=end
  def select_group_loan_to_start
    setup_select_group_loan
    @pending_approval_group_loans = @office.pending_approval_group_loans
  end
  
  def select_started_group_loan_to_be_managed
    setup_select_group_loan
    @started_group_loans = @office.started_group_loans
  end
  
  
  def execute_start_group_loan
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == APPROVER_ROLE
      if @action_value == TRUE_CHECK
        @group_loan.start_group_loan( current_user )
      elsif @action_value == FALSE_CHECK
        @group_loan.reject_group_loan_proposal( current_user )
      end
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
=begin
  Role == Field Worker 
  Select group loan for setup payment 
=end
  
  def select_group_loan_for_setup_payment
    @office = current_user.active_job_attachment.office
    @started_group_loans = @office.started_group_loans
  end
  
  def execute_setup_fee_collection_finalization
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == PROPOSER_ROLE 
      @group_loan.execute_finalize_setup_fee_collection( current_user )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
=begin
  Role == Cashier 
=end
  
  def select_group_loan_for_setup_payment_collection_approval
    @office = current_user.active_job_attachment.office
    @pending_setup_collection_group_loans = @office.pending_setup_collection_group_loans
  end
  
  
  def approve_setup_fee_collection
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == APPROVER_ROLE
      if @action_value == TRUE_CHECK
        @group_loan.approve_setup_fee_collection( current_user )
      elsif @action_value == FALSE_CHECK
        @group_loan.reject_setup_fee_collection( current_user )
      end
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
  # in disbursing the loan 
  
  def select_group_loan_for_loan_disbursement 
    @office = current_user.active_job_attachment.office
    @disbursable_group_loans = @office.disbursable_group_loans
  end
  
  def execute_loan_disbursement_finalization
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    if @action_role == PROPOSER_ROLE 
      @group_loan.execute_finalize_loan_disbursement( current_user )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
  # loan collection 
  def select_group_loan_for_weekly_meeting_attendance_marking
    @office = current_user.active_job_attachment.office
    @running_group_loans = @office.running_group_loans
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
