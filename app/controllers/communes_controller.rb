class CommunesController < ApplicationController  
  def select_commune_for_group_loan_assignment
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    @office = current_user.active_job_attachment.office
    @communes_array_list = @office.all_communes_under_management
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_to_assign_non_commune_constrained_member_url'
    set_breadcrumb_for @group_loan, 'select_commune_for_group_loan_assignment_url' + "(#{@group_loan.id})", 
                "Select Commune"
  end
  
  def list_members_in_commune
    @office = current_user.active_job_attachment.office
    @commune = Commune.find_by_id params[:commune_id]
    @village = @commune.village
    @subdistrict = @village.subdistrict
    
    @group_loan = GroupLoan.find_by_id params[:group_loan_id]
    
    add_breadcrumb "Select Group Loan", 'select_group_loan_to_assign_non_commune_constrained_member_url'
    set_breadcrumb_for @group_loan, 'select_commune_for_group_loan_assignment_url' + "(#{@group_loan.id})", 
                "Select Commune"
                
    set_breadcrumb_for @group_loan, 'list_members_in_commune_url' + "(#{@commune.id}, #{@group_loan.id})", 
                "Add Member"
  end
end
