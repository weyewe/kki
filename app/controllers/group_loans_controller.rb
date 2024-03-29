class GroupLoansController < ApplicationController
  
=begin
  Role == Branch Manager
=end

  def new
    setup_group_loan
    @new_group_loan = GroupLoan.new 
  end
  
  def create
    setup_group_loan
    @new_group_loan = GroupLoan.new(params[:group_loan])
    @new_group_loan.creator_id  = current_user.id 
    @new_group_loan.office_id = @office.id
    #GroupLoan.create_group_loan( params[:group_loan], current_user)
    
    if @new_group_loan.save
      flash[:notice] = "The new group loan has been created." + 
                    " To see the list, click <a href='#data_list'>here</a>."
      redirect_to new_group_loan_url 
    else
      flash[:error] = "Hey, do something better"
      render :file => "group_loans/new"
    end
  end
  
  
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
  
# list all active group loans, whose weekly tasks are all done 
  def select_group_loan_to_be_declared_as_default
    setup_select_group_loan
    @default_declarable_group_loans = @office.default_declarable_group_loans
  end
  
  def execute_declare_default_group_loan
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    if current_user.has_role?(:branch_manager, current_user.active_job_attachment )
      @group_loan.declare_default(current_user) 
    end
  end
  
  def select_group_loan_monitor_default_loan_resolution
    @office = current_user.active_job_attachment.office
    @default_declared_group_loans  = @office.default_declared_group_loans
  end
  
  
=begin
  To select group_loan in which member is gonna be assigned 
  role = LOAN_OFFICER
=end
  
  def select_group_loan_to_assign_member
    setup_select_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_assign_member_url'
  end
  
  def select_group_loan_to_assign_non_commune_constrained_member
    setup_select_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_assign_non_commune_constrained_member_url'
  end
  
  def select_group_loan_to_group_loan_product
    setup_select_group_loan
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_group_loan_product_url'
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
  


  
  def select_group_loan_to_create_field_worker_assignment
    setup_select_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_create_field_worker_assignment_url'
  end
  
  def select_group_loan_to_create_loan_inspector_assignment
    setup_select_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_create_loan_inspector_assignment_url'
  end
  
=begin
  Role == Field Worker 
  Select group loan for setup payment 
=end
  
  def select_group_loan_for_setup_payment
    @office = current_user.active_job_attachment.office
    @started_group_loans = @office.started_group_loans
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_setup_payment_url'
    
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
  
  # def select_group_loan_for_backlog_weekly_payment
  #   @office = current_user.active_job_attachment.office
  #   @running_group_loans = @office.running_group_loans
  #   
  #   add_breadcrumb "Select Group Loan", 'select_group_loan_for_backlog_weekly_payment_path'
  #   
  # end
  
  
  
  
  
=begin
  INDEPENDENT PAYMENT
=end

  def select_group_loan_for_independent_weekly_payment
    @office = current_user.active_job_attachment.office
    @running_group_loans = @office.running_group_loans
    
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_independent_weekly_payment_url'
  end
  
  def select_member_for_independent_weekly_payment
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @glm_list = @group_loan.active_group_loan_memberships.order("sub_group_id DESC, created_at ASC")
    
    @deadline_weekly_task = @group_loan.currently_executed_weekly_task
   
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_independent_weekly_payment_url'
    set_breadcrumb_for @group_loan, 'select_member_for_independent_weekly_payment_url' + "(#{@group_loan.id})", 
                "Select Member"
  end
  
  # approval by cashier 
  def select_group_loan_to_approve_independent_payment
    @office = current_user.active_job_attachment.office
    @running_group_loans = @office.running_group_loans.where(:is_grace_period => false)
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_approve_independent_payment_url'
  end
  
=begin
  GRACE PERIOD PAYMENT 
=end

  def select_group_loan_for_grace_period_payment
    @office = current_user.active_job_attachment.office
    
    @group_loans = []
    current_user.group_loans.each do |group_loan|
      if group_loan.is_grace_period?
        @group_loans << group_loan
      end
        
    end
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_grace_period_payment_url'  
  end
  
  def default_members_for_grace_period_payment
    
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.active_group_loan_memberships.order("sub_group_id DESC, created_at ASC") 
   
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_grace_period_payment_url'
    set_breadcrumb_for @group_loan, 'default_members_for_grace_period_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.grace_period_payment'}"
  end
  
  def grace_period_payment_calculator
    @office = current_user.active_job_attachment.office
    @group_loan_membership = GroupLoanMembership.find_by_id(params[:group_loan_membership_id])
    @group_loan = @group_loan_membership.group_loan 
    if @group_loan_membership.default_payment.unpaid_grace_period_amount == BigDecimal("0")
      redirect_to default_members_for_grace_period_payment_url(@group_loan.id)
      return 
    end
     
     
    
    @member  = @group_loan_membership.member 
    @unpaid_backlogs_count = @group_loan_membership.unpaid_backlogs.count 
    @group_loan_product = @group_loan_membership.group_loan_product
    @amount_per_backlog_in_grace_period = @group_loan_product.grace_period_weekly_payment
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_grace_period_payment_url'
    set_breadcrumb_for @group_loan, 'default_members_for_grace_period_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.grace_period_payment'}"
    set_breadcrumb_for @group_loan, 'grace_period_payment_calculator_url' + "(#{@group_loan_membership.id})", 
          "#{t 'process.input_payment'}"           
  end
  
  def edit_grace_period_payment_calculator
    @office = current_user.active_job_attachment.office
    @group_loan_membership = GroupLoanMembership.find_by_id(params[:group_loan_membership_id])
    @group_loan = @group_loan_membership.group_loan 
    
    @member  = @group_loan_membership.member 
    @unpaid_backlogs_count = @group_loan_membership.unpaid_backlogs.count 
    @group_loan_product = @group_loan_membership.group_loan_product
    @amount_per_backlog_in_grace_period = @group_loan_product.grace_period_weekly_payment
    
    @pending_approval_grace_payment = @group_loan_membership.unapproved_grace_period_payment
    
    if @group_loan_membership.default_payment.unpaid_grace_period_amount == BigDecimal("0") and 
        @pending_approval_grace_payment.nil? 
      redirect_to default_members_for_grace_period_payment_url(@group_loan.id)
      return 
    end
     
     
    
    
    
    ### only for edit
    @unpaid_grace_payment_adjusted = @group_loan_membership.default_payment.unpaid_grace_period_amount.to_i + 
			@pending_approval_grace_payment.grace_payment_savings_withdrawal_amount.to_i +
			@pending_approval_grace_payment.total_transaction_amount.to_i	-
			@pending_approval_grace_payment.grace_payment_extra_savings_amount.to_i
			
		@total_available_extra_savings =   @member.saving_book.total_extra_savings.to_i +
			@pending_approval_grace_payment.grace_payment_savings_withdrawal_amount.to_i -
			@pending_approval_grace_payment.grace_payment_extra_savings_amount.to_i
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_grace_period_payment_url'
    set_breadcrumb_for @group_loan, 'default_members_for_grace_period_payment_url' + "(#{@group_loan.id})", 
                "#{t 'process.grace_period_payment'}"
    set_breadcrumb_for @group_loan, 'edit_grace_period_payment_calculator_url' + "(#{@group_loan_membership.id})", 
          "#{t 'process.input_payment'}"           
  end
  
=begin
  Approve GRACE PERIOD PAYMENT 
=end
  def select_group_loan_for_grace_period_payment_approval
    @office = current_user.active_job_attachment.office
    @group_loans = @office.group_loans_with_unapproved_grace_period_payment
  end
    
=begin
  DEFAULT PAYMENT RESOLUTION 
=end
  def select_group_loan_for_loan_default_resolution
    @office = current_user.active_job_attachment.office
    
    @group_loans = []
    current_user.group_loans.each do |group_loan|
      if group_loan.is_grace_period?
        @group_loans << group_loan
      end
        
    end
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_default_resolution_path'
  end
  
  def standard_default_resolution_schema
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_membership_id = @group_loan.preserved_active_group_loan_memberships.map{|x| x.id }
    
     
    @default_payments = DefaultPayment.where(
      :group_loan_membership_id => @group_loan_membership_id).order("group_loan_memberships.sub_group_id DESC, group_loan_memberships.created_at ASC").includes(:group_loan_membership)
    
    @total_defaultee = @default_payments.where(:is_defaultee => true ).count
    
    @total_default_payment_to_be_paid = BigDecimal("0")
    @default_payments.each do |dp|
      @total_default_payment_to_be_paid += dp.amount_to_be_paid
    end
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_default_resolution_path'
    set_breadcrumb_for @group_loan, 'standard_default_resolution_schema_url' + "(#{@group_loan.id})", 
                "#{t 'process.standard_default_resolution'}"
  end
  
   
  def execute_propose_standard_default_resolution
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @group_loan.propose_default_payment_execution(current_user)
  end
  
  
  def custom_default_resolution_schema
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_membership_id = @group_loan.preserved_active_group_loan_memberships.map{|x| x.id }
    
     
    @default_payments = DefaultPayment.where(
      :group_loan_membership_id => @group_loan_membership_id).order("group_loan_memberships.sub_group_id DESC, group_loan_memberships.created_at ASC").includes(:group_loan_membership)
    
    @total_defaultee = @default_payments.where(:is_defaultee => true ).count
    
    @total_default_payment_to_be_paid = BigDecimal("0")
    @default_payments.each do |dp|
      @total_default_payment_to_be_paid += dp.amount_to_be_paid
    end
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_default_resolution_path'
    set_breadcrumb_for @group_loan, 'custom_default_resolution_schema_url' + "(#{@group_loan.id})", 
                "#{t 'process.custom_default_resolution'}"
  end
  
  def execute_propose_custom_default_resolution
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @glm_payment_pair_list = [] 
    @total_amount = BigDecimal('0')
    params[:payment].each do |name, amount |
      glm_id = name.split("_")[1].to_i
      amount = BigDecimal(amount)
      @glm_payment_pair_list << {
       :glm_id =>  glm_id,
       :amount => amount
      }
      @total_amount += amount 
    end
    
    
    @payment_params = params[:payment]
    @group_loan.propose_custom_default_payment_execution(current_user, @glm_payment_pair_list)
    
    
    #  to replace the form
    @group_loan_membership_id = @group_loan.preserved_active_group_loan_memberships.map{|x| x.id } 
    @default_payments = DefaultPayment.where(
      :group_loan_membership_id => @group_loan_membership_id).order("group_loan_memberships.sub_group_id DESC, group_loan_memberships.created_at ASC").includes(:group_loan_membership)
      
  end
  
  
=begin
  DEFAULT PAYMENT Resolution: Execution by cashier
=end
  def select_group_loan_for_default_resolution_execution
    @office = current_user.active_job_attachment.office
    @group_loans = @office.group_loans_for_default_resolution_execution
  end
  
  def execute_default_resolution
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    
    @action = params[:action_value].to_i
    
    if @action == TRUE_CHECK
      # @transaction.approve_backlog_payments(current_user) 
      puts "YEAH< GONNA EXECUTE DEFAULT PAYMENT EXECUTION"
      # @group_loan.execute_default_payment_execution( current_user ) 
    elsif 
      @action == FALSE_CHECK
      
      puts "SIBE KIA, NOT EXECUTING DEFAULT PAYMENT EXECUTION"
      @group_loan.cancel_default_payment_proposal( current_user ) 
    end
    # 
  end
  
=begin
  Branch MANAGER CLOSE THE GROUP LOAN
=end
  def close_group_loan
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @group_loan.close_group_loan(current_user)
  end

  def select_closed_group_loan_for_history
    @office = current_user.active_job_attachment.office
    @closed_group_loans  = @office.closed_group_loans
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
  
  
  
=begin
  Marking the financial education attendance 
=end
  
  def select_group_loan_for_financial_education_meeting_attendance
    setup_group_loan
    @active_group_loans = @office.started_group_loans
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_financial_education_meeting_attendance_url'
  end
  
  
  def mark_financial_education_attendance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.group_loan_memberships.includes(:member).order("sub_group_id DESC, created_at ASC")
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_financial_education_meeting_attendance_url'
    set_breadcrumb_for @group_loan, 'mark_financial_education_attendance_url' + "(#{@group_loan.id})", 
                "#{t 'process.financial_education_attendance'}"
  end
  
  def propose_finalization_for_financial_education
    @group_loan   = GroupLoan.find_by_id params[:entity_id]
    
    @group_loan.propose_financial_education_attendance_finalization(current_user)
  end
  
  # the loan inspector version
  def select_group_loan_for_financial_education_finalization
    setup_group_loan
    @active_group_loans = @office.started_group_loans
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_financial_education_finalization_url'
  end
  
  def finalize_financial_education_attendance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.group_loan_memberships.includes(:member).order("created_at DESC")
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_financial_education_finalization_url'
    set_breadcrumb_for @group_loan, 'finalize_financial_education_attendance_url' + "(#{@group_loan.id})", 
                "#{t 'process.financial_education_attendance'}"
  end
  
  def execute_finalize_financial_education
    @group_loan   = GroupLoan.find_by_id params[:entity_id]
    
    @group_loan.finalize_financial_attendance_summary(current_user)
  end
  
=begin
  Marking the Loan Disbursement Attendance
=end
  def select_group_loan_for_loan_disbursement_meeting_attendance
    setup_group_loan
    @active_group_loans = @office.loan_disbursement_meeting_group_loans
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_disbursement_meeting_attendance_url'
  end
  
  def mark_loan_disbursement_attendance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.group_loan_memberships_attendance_display_for_loan_disbursement.includes(:member).order("sub_group_id DESC, created_at ASC")
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_disbursement_meeting_attendance_url'
    set_breadcrumb_for @group_loan, 'mark_loan_disbursement_attendance_url' + "(#{@group_loan.id})", 
                "Loan Disbursement Attendance"
  end
  
  def propose_finalization_for_loan_disbursement
    @group_loan   = GroupLoan.find_by_id params[:entity_id]
    
    @group_loan.propose_loan_disbursement_attendance_finalization(current_user)
    
    # only happen in the web app 
    # on finalization -> auto create all loan disbursement transactions 
    
    # TransactionActivity.execute_loan_disbursement( glm , @field_worker )
    
   
    
  end
  
  # loan inspector part
  def select_group_loan_for_loan_disbursement_attendance_finalization
    setup_group_loan
    @active_group_loans = @office.started_group_loans
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_disbursement_attendance_finalization_url'
  end
  
  
   
  
  def finalize_loan_disbursement_attendance
    @office = current_user.active_job_attachment.office
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @group_loan_memberships = @group_loan.group_loan_memberships_attendance_display_for_loan_disbursement.includes(:member).order("created_at DESC")
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_loan_disbursement_attendance_finalization_url'
    set_breadcrumb_for @group_loan, 'finalize_loan_disbursement_attendance_url' + "(#{@group_loan.id})", 
                "Loan Disbursement Attendance"
  end


  def execute_finalize_loan_disbursement_attendance
    @group_loan   = GroupLoan.find_by_id params[:entity_id]
    
    # transaction here.. if some shit happens, it will raise up all the way, and rollback
    
    begin
      ActiveRecord::Base.transaction do
        @group_loan.finalize_loan_disbursement_attendance_summary(current_user)
          # case, over here, it is not being executed. dafuq.. 
          # financial data -> error is expensive. move the database to production.
          # then, hope that every transactions will happen 
        if @group_loan.is_loan_disbursement_attendance_done == true 
          @group_loan.active_group_loan_memberships.each do |glm|
            TransactionActivity.execute_automatic_loan_disbursement(glm, current_user)
          end
        end
      end
    rescue ActiveRecord::ActiveRecordError  
    else
    end


    
    
  end


=begin
  For LOAN DISBURSEMENT 
=end
  
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
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_meeting_attendance_marking_path'
  end
  
  def select_group_loan_for_weekly_payment
    setup_group_loan_for_weekly_task
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_for_weekly_payment_path'
  end
  
=begin
  Group Member Management 
=end
  def select_group_loan_to_select_group_leader
    setup_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_select_group_leader_url'
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
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_select_group_leader_url'
    set_breadcrumb_for @group_loan, 'select_group_leader_from_member_url' + "(#{@group_loan.id})", 
                "#{t 'process.assign_group_leader'}"
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
    redirect_to select_group_leader_from_member_url(@group_loan.id)
  end
  
  def select_group_loan_to_create_sub_group
    setup_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_create_sub_group_url'
  end
  
  def select_group_loan_to_assign_member_to_sub_group
    setup_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_assign_member_to_sub_group_url'
  end
  
  def select_group_loan_to_select_sub_group_leader
    setup_group_loan
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_select_sub_group_leader_url'
  end
  
  
  
=begin
  Approval of the backlog payment 
=end
  def select_group_loan_for_backlog_payment_approval
    @office = current_user.active_job_attachment.office
    @active_group_loans = @office.active_group_loans
    
  end

=begin
  Disbursing the Savings from group loan
=end

  def select_group_loan_for_savings_disbursement_start
    setup_group_loan_for_flushing_voluntary_savings 
    add_breadcrumb "Pending Pengembalian Tabungan", 'select_group_loan_for_savings_disbursement_start_url'
  end
  
  def execute_savings_disbursement_start
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    @group_loan.start_group_loan_savings_disbursement( current_user ) 

   
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end

  def select_group_loan_to_propose_savings_disbursement_finalization
    setup_group_loan_for_flushing_voluntary_savings
    add_breadcrumb "Pending Pengembalian Tabungan", 'select_group_loan_to_propose_savings_disbursement_finalization_url'
  end
  
  def add_details_to_propose_savings_disbursement_finalization
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @office = current_user.active_job_attachment.office
    @payment_params = nil 
    add_breadcrumb "Pending Pengembalian Tabungan", 'select_group_loan_to_propose_savings_disbursement_finalization_url'
    set_breadcrumb_for @group_loan, 'add_details_to_propose_savings_disbursement_finalization_url' + "(#{@group_loan.id})", 
                "Lengkapi Pengembalian Tabungan"
  end
   
  
  def execute_propose_savings_disbursement_finalization
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @glm_savings_disbursement_saved_list = [] 
    @total_amount = BigDecimal('0')
    params[:payment].each do |name, amount |
      glm_id = name.split("_")[1].to_i
      amount = BigDecimal(amount)
      @glm_savings_disbursement_saved_list << {
       :glm_id =>  glm_id,
       :amount => amount
      }
      @total_amount += amount 
    end
    
    @payment_params = params[:payment]
    @group_loan.propose_savings_disbursement_finalization(current_user, @glm_savings_disbursement_saved_list)
  end
  
  def select_group_loan_for_savings_disbursement_finalization
    setup_group_loan_for_flushing_voluntary_savings
    add_breadcrumb "Finalisasi Pengembalian Tabungan", 'select_group_loan_for_savings_disbursement_finalization_url'
  end
  
  def finalize_savings_disbursement
    @group_loan = GroupLoan.find_by_id params[:entity_id]
    @action_role = params[:action_role].to_i
    @action_value = params[:action_value].to_i
    
    @group_loan.finalize_savings_disbursement( current_user ) 

   
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js 
    end
  end
  
=begin
  MEMBER PAYMENT HISTORY
=end
  def select_group_loan_to_view_payment_history
    @office = current_user.active_job_attachment.office
    @group_loans = @office.group_loans.order("created_at DESC")
    
    add_breadcrumb "#{t 'process.select_group_loan'}", 'select_group_loan_to_view_payment_history_url'
  end
  
  

  
  protected
  
  def setup_group_loan_for_flushing_voluntary_savings
    @office = current_user.active_job_attachment.office
    @group_loans = @office.pending_savings_disbursement
  end
  
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
