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
  end # end of before(:each block)
   
   
  
  
  it 'should not allow savings_account transaction if there is unapproved previous transaction (on a given member)' do
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_valid
    
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_nil 
  end
  
  it 'should not allow savings_account transaction if the nominal is less than 1000 rupiah'  do
    amount = MIN_SAVINGS_ACCOUNT_AMOUNT_DEPOSIT - BigDecimal('5')
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , amount)
    transaction_activity.should be_nil
  end
  
  it 'should create 2-steps to create new savings account' do
    # create the transaction_activity.. then, confirm it 
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_valid 
    transaction_activity.is_approved.should be_false 
    
    transaction_activity.confirm_savings_account_addition(@cashier) 
    transaction_activity.is_approved.should be_true 
  end
  
  it 'should be deletable if it is not confirmed yet' do
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.should be_valid
    transaction_activity.persisted?.should be_true 
    
    transaction_activity.delete_savings_account_transaction( @cashier ) 
    transaction_activity.persisted?.should be_false 
  end
  
  it 'should not be deletable if it is confirmed' do
    transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
    transaction_activity.confirm_savings_account_addition(@cashier) 
    
    transaction_activity.delete_savings_account_transaction(@cashier)
    transaction_activity.persisted?.should be_true 
  end
  
  context "post confirm transaction activity" do
    before(:each) do
      @initial_savings_account_amount = @first_member.saving_book.total_savings_account 
      @transaction_activity = TransactionActivity.add_savings_account( @cashier, @first_member , BigDecimal('50000'))
      @transaction_activity.confirm_savings_account_addition(@cashier) 
      @first_member.reload 
    end
    
    
    it 'should create a corresponding transaction entry and savings entry for savings_account_addition' do
      transaction_entries= @transaction_activity.transaction_entries.
                                where(
                                    :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:add_savings_account]
                                )
      transaction_entries.length.should == 1 
      
      transaction_entry = transaction_entries.first 
      transaction_entry.amount.should == @transaction_activity.total_transaction_amount
    end
    
    it 'should create a savings_entry corresponding to the addition' do
      transaction_entries= @transaction_activity.transaction_entries.
                                where(
                                    :transaction_entry_code =>  TRANSACTION_ENTRY_CODE[:add_savings_account]
                                ) 
      
      transaction_entry = transaction_entries.first  
      
      saving_entries = SavingEntry.where(
        :saving_book_id => @first_member.saving_book.id , 
        :saving_entry_code => SAVING_ENTRY_CODE[:add_savings_account], 
        :saving_action_type => SAVING_ACTION_TYPE[:debit] ,
        :transaction_entry_id => transaction_entry.id,
        :savings_case => SAVING_CASE[:savings_account]
      )
      
      saving_entries.length .should == 1 
      saving_entry = saving_entries.first 
      saving_entry.amount.should == @transaction_activity.total_transaction_amount
    end
    
    it 'should add total savings_account by the transaction amount' do
      @final_savings_account_amount = @first_member.saving_book.total_savings_account 
      diff = @final_savings_account_amount - @initial_savings_account_amount 
      diff.should ==  @transaction_activity.total_transaction_amount
    end 
  end
   
end