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
=end
  
  def select_group_loan_to_assign_member
    @office = current_user.active_job_attachment.office
    @active_group_loans = @office.active_group_loans
  end
  
  protected
  def setup_group_loan
    @office = current_user.active_job_attachment.office
    @active_group_loans = @office.active_group_loans
    @all_communes = @office.all_communes_under_management
  end
end
