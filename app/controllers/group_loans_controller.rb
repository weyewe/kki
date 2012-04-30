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
  
  def select_group_loan_for_backlog_weekly_payment
    @office = current_user.active_job_attachment.office
    @running_group_loans = @office.running_group_loans
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
    setup_group_loan_for_weekly_task
    add_breadcrumb "Select GroupLoan", 'select_group_loan_for_weekly_meeting_attendance_marking_path'
  end
  
  def select_group_loan_for_weekly_payment
    setup_group_loan_for_weekly_task
    
    add_breadcrumb "Select GroupLoan", 'select_group_loan_for_weekly_payment_path'
  end
  
=begin
  Group Member Management 
=end
  def select_group_loan_to_select_group_leader
    setup_group_loan
  end
  
  # @office = current_user.active_job_attachment.office
  #  @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
  #  @commune_members = @group_loan.commune.members
  
  def select_group_leader_from_member
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @members = @group_loan.members.includes(:group_loan_memberships) 
    @group_leader_id = @group_loan.group_leader_id
    if @group_leader_id.nil?
      @group_leader_name = ''
    else
      @group_leader_name = @group_loan.group_leader.name 
    end
    # @group_leader_name = nil if @group_leader_id.nil? else @group_loan.group_leader.name 
  end
  
  
  def execute_select_group_leader
    @group_loan = GroupLoan.find_by_id params[:membership_provider]
    @member = Member.find_by_id params[:membership_consumer]
    membership_decision = params[:membership_decision].to_i
    
    if membership_decision == TRUE_CHECK
      @group_loan.set_group_leader( @member )
    elsif membership_decision == FALSE_CHECK
      @group_loan.remove_group_leader
    end
    redirect_to select_group_leader_from_member_url(@group_loan)
  end
  
  def select_group_loan_to_create_sub_group
    setup_group_loan
  end
  
  def select_group_loan_to_assign_member_to_sub_group
    setup_group_loan
  end
  
  def select_group_loan_to_select_sub_group_leader
    setup_group_loan
  end
  
  protected
  
  def setup_group_loan_for_weekly_task
    @office = current_user.active_job_attachment.office
    @running_group_loans = @office.running_group_loans
  end
  
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
