class SubGroupsController < ApplicationController
  def new
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @sub_groups = @group_loan.sub_groups.order("number ASC")
    @new_sub_group_loan = SubGroup.new 
  end
  
  def create
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    
    if not params[:total_sub_groups].nil?
      SubGroup.set_sub_groups( @group_loan, params[:total_sub_groups].to_i )
      # @group_loan.set_sub_groups( params[:sub_group][:total_sub_groups])
      redirect_to new_group_loan_sub_group_url(@group_loan, :notice => "Total sub groups is #{params[:total_sub_groups]}")
    else
      redirect_to new_group_loan_sub_group_url(@group_loan, :error => "Sub Groups Creation Fails")
    end
      
  end
  
  def select_sub_group_to_assign_members
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @sub_groups = @group_loan.sub_groups.order("number ASC")
  end
  
  def assign_member_to_sub_group
    @sub_group = SubGroup.find_by_id params[:sub_group_id]
    @group_loan = @sub_group.group_loan 
    @members = @group_loan.members
  end
  
  
  def select_sub_group_to_pick_leader
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @sub_groups = @group_loan.sub_groups.order("number ASC")
  end
end
