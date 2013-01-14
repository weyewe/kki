class SavingsEntriesController < ApplicationController
  def new_voluntary_savings_adjustment
    @office = current_user.active_job_attachment.office
    # @office_members = @office.members
    # @all_communes = @office.all_communes_under_management
  end
  
  def generate_savings_account_creation_form_summary
    @member = Member.find_by_id params[:transaction_activity][:member_id]
    @transaction_activities = TransactionActivity.savings_account_transactions(@member)
    render :file => 'savings_entries/savings_accounts/generate_savings_account_creation_form_summary'
  end
  
  
  
  def new_savings_account_deposit
    @transaction_activity = TransactionActivity.new 
    @office = current_user.active_job_attachment.office 
    
    render :file => 'savings_entries/savings_accounts/new_savings_account_deposit'
  end 
  
  def new_savings_account
    @member = Member.find_by_id params[:member_id]
    render :file => 'savings_entries/savings_accounts/new_savings_account' 
  end
  
  def create_savings_account
    @member = Member.find_by_id params[:member_id]
    render :file => 'savings_entries/savings_accounts/create_savings_account' 
  end
  
end
