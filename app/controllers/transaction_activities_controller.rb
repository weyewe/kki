class TransactionActivitiesController < ApplicationController
  def create_transaction_activity_for_setup_payment
    sleep 2 
    
    # "member_id"=>"1", "admin_fee"=>"25000", "initial_savings"=>"15000", "deposit"=>"2432432"
    
    admin_fee = BigDecimal.new( params[:admin_fee] )
    initial_savings = BigDecimal.new( params[:initial_savings] )
    deposit = BigDecimal.new( params[:deposit] )
    member = Member.find_by_id( params[:member_id] )
    
    TransactionActivity.create_setup_payment( admin_fee, initial_savings,
                                            deposit, current_user, member )
  end
  
  
end
