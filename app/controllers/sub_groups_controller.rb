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
  
=begin
  Assign member to sub group 
=end
  def select_sub_group_to_assign_members
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @sub_groups = @group_loan.sub_groups.order("number ASC")
  end
  
  def assign_member_to_sub_group
    @sub_group = SubGroup.find_by_id params[:sub_group_id]
    @group_loan = @sub_group.group_loan 
    @members = @group_loan.members
  end
  
  def execute_sub_group_assignment
    @member = Member.find_by_id params[:membership_consumer]
    @sub_group  = SubGroup.find_by_id params[:membership_provider]
   
    @group_loan = @sub_group.group_loan 
    
    decision = params[:membership_decision].to_i
    
    if decision == TRUE_CHECK
      @sub_group.add_member( @member ) 
    elsif decision == FALSE_CHECK
      @sub_group.remove_member( @member )
    end
    
    @group_loan_membership = @sub_group.get_group_loan_membership( @member )
    
  end
  
  
=begin
  Pick Sub group leader
=end

  def select_sub_group_to_pick_leader
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @sub_groups = @group_loan.sub_groups.order("number ASC")
  end
  
  def select_sub_group_leader_from_sub_group
    @sub_group = SubGroup.find_by_id params[:sub_group_id]
    @group_loan = @sub_group.group_loan 
    @group_loan_memberships_from_subgroup = @sub_group.group_loan_memberships.includes(:member)
    @sub_group_leader_id = @sub_group.sub_group_leader_id
  end
  
  
  
  def execute_select_sub_group_leader
    @sub_group = SubGroup.find_by_id params[:membership_provider]
    @member = Member.find_by_id params[:membership_consumer]
    membership_decision = params[:membership_decision].to_i
    @group_loan = @sub_group.group_loan 
    
    if membership_decision == TRUE_CHECK
      @sub_group.set_group_leader( @member )
    elsif membership_decision == FALSE_CHECK
      @sub_group.remove_group_leader
    end
    redirect_to select_sub_group_leader_from_sub_group_url( @sub_group )
  end
  
  
  
  

  
end
