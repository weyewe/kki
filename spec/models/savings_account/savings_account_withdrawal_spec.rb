require 'spec_helper'

describe SavingBook do
  before(:each) do
    @office = FactoryGirl.create(:cilincing_office)
    @branch_manager_role = FactoryGirl.create(:branch_manager_role)
    @loan_officer_role = FactoryGirl.create(:loan_officer_role)
    @cashier_role = FactoryGirl.create(:cashier_role)
    @field_worker_role = FactoryGirl.create(:field_worker_role)
    @branch_manager = @office.create_user( [@branch_manager_role],
      :email => 'branch_manager@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @loan_officer = @office.create_user( [@loan_officer_role], 
      :email => 'loan_officer@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @cashier = @office.create_user( [@cashier_role], 
      :email => 'cashier@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    @field_worker = @office.create_user( [@field_worker_role], 
      :email => 'field_worker@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    
    @group_loan_commune = FactoryGirl.create(:group_loan_commune)
    #this shit will trigger the creation of kalibaru village, cilincing subdistrict 
    
    # @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
    #          :commune_id => @group_loan_commune.id }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id ) 
     
    @first_member = @members.first 
    @savings_amount  = BigDecimal('50000')
    @transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member ,  @savings_amount)
    @transaction_activity.confirm_savings_account_addition(@cashier) 
    @first_member.reload 
    @initial_total_savings_account = @first_member.saving_book.total_savings_account
  end # end of before(:each block)
   
  it 'should have initial savings_account' do
    @first_member.saving_book.total_savings_account.should == @savings_amount
  end
  
  it 'should not be able to deduct more than total savings account' do
    @excess_amount = @savings_amount +  BigDecimal("100")
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member, @excess_amount)
    transaction_activity.should be_nil 
  end
  
  it 'should not allow savings_account transaction if there is unconfirmed savings_account' do
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_valid
    
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_nil 
  end
  
  it 'should not allow savings_account transaction if there is unconfirmed savings_account' do
    less_amount = @savings_amount - BigDecimal("1000")
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member ,less_amount )
    transaction_activity.should be_valid
    
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member , less_amount )
    transaction_activity.should be_nil 
  end
  
  
  it 'should not deduct before confirmation'  do
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member , BigDecimal('50000'))
    @first_member.reload 
    @final_total_savings_account = @first_member.saving_book.total_savings_account
    
    diff = @final_total_savings_account  - @initial_total_savings_account
    
    diff.should == BigDecimal("0")
  end
  
  it 'should be deletable if not confirmed' do
    
    transaction_activity = TransactionActivity.withdraw_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.persisted?.should be_true 
    
    transaction_activity.delete_savings_account_transaction(@cashier)
    
    transaction_activity.persisted?.should be_false 
  end
   
  
  context "post deduction (confirmation)" do
    before(:each) do
    end
    
    it 'should produce transaction activity with outward (credit)'
    
    it 'should produce the accompanying transaction entry'
    
    it 'should produce the saving_entry to deduct the total_savings_account'
    
    it 'should deduct the total savings account' 
  end
    
   
end