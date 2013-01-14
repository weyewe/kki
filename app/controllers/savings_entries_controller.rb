class SavingsEntriesController < ApplicationController
  def new_voluntary_savings_adjustment
    @office = current_user.active_job_attachment.office
    # @office_members = @office.members
    # @all_communes = @office.all_communes_under_management
  end
  
  def new_savings_account_deposit
    @transaction_activity = TransactionActivity.new 
    @office = current_user.active_job_attachment.office 
    
    render :file => 'savings_entries/savings_accounts/new_savings_account_deposit'
  end
  
  def generate_savings_account_creation_form_summary
    @member = Member.find_by_id params[:transaction_activity][:member_id]
    @transaction_activities = TransactionActivity.savings_account_transactions(@member)
    render :file => 'savings_entries/savings_accounts/generate_savings_account_creation_form_summary'
  end
   
  
  def new_savings_account
    @member = Member.find_by_id params[:member_id]
    @new_object  = TransactionActivity.new
    @amount = BigDecimal("0")
    render :file => 'savings_entries/savings_accounts/new_savings_account' 
  end
  
  def create_savings_account
    @member = Member.find_by_id params[:member_id]
    
    # a  = BigDecimal("0.5")
    # a.round will give 1 
    ## a  = BigDecimal("0.4")
    ## a.round will give 0 
    
     # a.errors.messages[:password]
    @amount  = BigDecimal("#{params[:transaction_activity][:amount]}")
    @object = ''
     puts "\n\nWhat is this\n\n"
    if params[:transaction_activity][:transaction_action_type].to_i == TRANSACTION_ACTION_TYPE[:inward]
      puts "Doing savings"
      @object = TransactionActivity.add_savings_account( current_user, @member, @amount)
    elsif params[:transaction_activity][:transaction_action_type].to_i == TRANSACTION_ACTION_TYPE[:outward]
      puts "doing withdrawal"
      @object = TransactionActivity.withdraw_savings_account( current_user, @member, @amount) 
    end
    
    
      
    @new_object= @object 
    
    
     
   
     
    render :file => 'savings_entries/savings_accounts/create_savings_account' 
  end
  
  def edit_savings_account
  end
  
end
