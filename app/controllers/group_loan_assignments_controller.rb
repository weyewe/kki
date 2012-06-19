class GroupLoanAssignmentsController < ApplicationController
  def new_field_worker_assignment_to_employee
    new_assignment_setup
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_to_create_field_worker_assignment_url'
    set_breadcrumb_for @group_loan, 'new_field_worker_assignment_to_employee_url' + "(#{@group_loan.id})", 
                "Create Field Worker Assignment"
  end
  
  def execute_field_worker_assignment
    execute_assignment_setup
    
    # only for field_worker assignment 
    # @group_loan.add_assignment(:field_worker, @field_worker)
    # @group_loan.add_assignment(:loan_inspector, @branch_manager)
    
    
    if @decision == TRUE_CHECK
      @new_group_loan_assignment = @group_loan.add_assignment(:field_worker, @user )
    elsif @decision == FALSE_CHECK
      @new_group_loan_assignment = @group_loan.destroy_assignment( :field_worker,  @user )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js
    end
  end
  
  
  def new_loan_inspector_assignment_to_employee
    new_assignment_setup
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_to_create_loan_inspector_assignment_url'
    set_breadcrumb_for @group_loan, 'new_field_worker_assignment_to_employee_url' + "(#{@group_loan.id})", 
                "Create Field Worker Assignment"
  end
  
  def execute_loan_inspector_assignment
    execute_assignment_setup
    
    # only for field_worker assignment 
  
    puts "gonna enter the decision tree"
    
    puts "***********\n"*5
    puts "The user email: #{@user.email}"
    if @decision == TRUE_CHECK
      puts "The decision is #{@decision}, gonna add assignment"
      @new_group_loan_assignment = @group_loan.add_assignment(:loan_inspector, @user )
    elsif @decision == FALSE_CHECK
      puts "The decision is #{@decision}, gonna destroy assignment"
      @new_group_loan_assignment = @group_loan.destroy_assignment( :loan_inspector,  @user )
    end
    
    respond_to do |format|
      format.html {  redirect_to root_url }
      format.js
    end
  end
  
  protected
  def new_assignment_setup
    @group_loan = GroupLoan.find_by_id( params[:group_loan_id])
    @office = current_user.active_job_attachment.office
    @users = @office.users
  end
  
  def execute_assignment_setup
    @decision = params[:membership_decision].to_i
    @group_loan = GroupLoan.find_by_id params[:membership_provider]
    @user = User.find_by_id params[:membership_consumer]
    @new_group_loan_assignment = ''
  end
end
