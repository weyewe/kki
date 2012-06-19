=begin
  LoanDisbursementTransactionActivitySpec is a subset of transaction activity.
  Focusing on testing loan disbursement logic
  
=end
require 'spec_helper'

describe TransactionActivity do
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
    #          :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
    
    #
    # => Group loan specific
    #
    
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", 
              :commune_id => @group_loan_commune }, @branch_manager)

    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
    end
    
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
        @group_loan_product_c] 
        
    @group_loan.group_loan_memberships.each do |glm|
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    @group_loan.add_assignment(:field_worker, @field_worker)
    @group_loan.add_assignment(:loan_inspector, @branch_manager)
    
    @group_loan.execute_propose_finalization( @loan_officer )
    @group_loan.start_group_loan( @branch_manager )
    
    count = 1
    @group_loan.group_loan_memberships.each do |glm|
      attendance = false
      if count%2 != 0 
        attendance = true 
      end
      count += 1 
      glm.mark_financial_education_attendance( @field_worker, attendance, @group_loan  )
    end
    # we have 4 failed in education attendance
    
    @group_loan.finalize_financial_attendance_summary(@branch_manager)
  
  end
  
  
  context "pre condition of loan disbursement transaction" do 
    
    it "should not create loan disbursement transaction if the loan attendance has not been marked" do
      first_glm = @group_loan.group_loan_memberships.first
      @group_loan.group_loan_memberships.each do |glm|
        if glm.id == first_glm.id
          next #not marking the first_glm loan disbursement attendance
        else
          glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
        end
      end
       
      first_transaction = TransactionActivity.execute_loan_disbursement( first_glm , @field_worker)
      first_transaction.should be_nil
    end
    
    it 'should not create loan disbursement  transaction if the membership is not active' do
      first_glm = @group_loan.group_loan_memberships.first
      @group_loan.group_loan_memberships.each do |glm|
        if glm.id == first_glm.id
          glm.mark_loan_disbursement_attendance( @field_worker, false, @group_loan  )
        else
          glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
        end
      end
      
      first_transaction = TransactionActivity.execute_loan_disbursement( first_glm , @field_worker)
      # the result of that transaction activity should be nil 
      first_transaction.should be_nil
    end
    
    it 'should  create loan disbursement  transaction if the membership is active and attending both financial education + finalized' do

      @group_loan.group_loan_memberships.each do |glm|
        glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
      end
      
      @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager)
      first_glm = @group_loan.group_loan_memberships.first
      first_transaction = TransactionActivity.execute_loan_disbursement( first_glm , @field_worker)
      # the result of that transaction activity should be nil 
      first_transaction.should be_valid
    end
    
    it "will return the transaction_activity if it has been executed previously" do 
      @group_loan.group_loan_memberships.each do |glm|
        glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
      end
      
      @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager)
      first_glm = @group_loan.group_loan_memberships.first
      first_transaction = TransactionActivity.execute_loan_disbursement( first_glm , @field_worker)
      
      second_transaction = TransactionActivity.execute_loan_disbursement( first_glm , @field_worker)
      second_transaction.id.should == first_transaction.id 
    end
    
  end
  
  context "post creation" do
    before(:each) do
      @group_loan.group_loan_memberships.each do |glm|
        glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
      end
      
      @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager)
      @glm = @group_loan.group_loan_memberships.first
      @member = @glm.member 
      @initial_total_savings = @member.saving_book.total
      @initial_compulsory_savings = @member.saving_book.total_compulsory_savings
      @initial_extra_savings = @member.saving_book.total_extra_savings
      
      @transaction_1_executed = TransactionActivity.execute_loan_disbursement( @glm , @field_worker)
    end
    
    it "will deduct the disbursement amount if the deposit is done by 'loan deduction scheme'" do
      group_loan_product = @glm.group_loan_product 
      full_loan_amount  = group_loan_product.loan_amount
      setup_fee = group_loan_product.setup_payment_amount
    
      total_money_received_by_member = full_loan_amount - setup_fee
      
      puts "actual value is #{@transaction_1_executed.total_transaction_amount}"
      puts "expected value is #{total_money_received_by_member}"
      @transaction_1_executed.total_transaction_amount.should  ==  total_money_received_by_member 
    end

    
    
    it "will create 3 transaction entries: giving the full amount to the member, 
        and the member will return the one equal with setup amount: 1 admin fee and 1 saving entry " do
      @transaction_1_executed.transaction_case.should ==TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]             
      @transaction_1_executed.should have(3).transaction_entries 
    
    
      group_loan_product = @glm.group_loan_product 
      full_loan_amount  = group_loan_product.loan_amount
      setup_fee = group_loan_product.setup_payment_amount - group_loan_product.initial_savings
      paid_initial_savings = group_loan_product.initial_savings
      total_money_exchanging_hands = full_loan_amount - setup_fee - paid_initial_savings
      
      
      # check the transaction entries case 
      deduction_loan_disbursement_for_admin_count = 0 
      deducted_loan_disbursement_for_initial_savings_count = 0
      deducted_loan_disbursement_count = 0
      amount_of_deducted_loan_disbursement = BigDecimal("0")
      amount_of_loan_disbursement_deduction = BigDecimal('0')
      
      @transaction_1_executed.transaction_entries.each do  |t_entry|
        if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:total_loan_disbursement_amount]
          deducted_loan_disbursement_count += 1 
          ( total_money_exchanging_hands + setup_fee+ paid_initial_savings).should == t_entry.amount
        end
        if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:setup_fee_deduction_from_disbursement_amount]
          deduction_loan_disbursement_for_admin_count += 1 
          setup_fee.should == t_entry.amount
        end
        
        if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:initial_savings]
          deducted_loan_disbursement_for_initial_savings_count += 1 
          paid_initial_savings.should == t_entry.amount
        end
      end
    
      deducted_loan_disbursement_count.should ==  1 
      deduction_loan_disbursement_for_admin_count.should  == 1 
      deducted_loan_disbursement_for_initial_savings_count.should == 1 
      @transaction_1_executed.total_transaction_amount.should  ==  total_money_exchanging_hands 
    end  # end of the it block
    
    it "will increase total savings and compulsory savings" do
      # @initial_total_savings = @member.saving_book.total
      #   @initial_compulsory_savings = @member.saving_book.total_compulsory_savings
      #   @initial_extra_savings = @member.saving_book.total_extra_savings
      
      final_total_savings = @member.saving_book.total
      final_compulsory_savings = @member.saving_book.total_compulsory_savings
      final_extra_savings = @member.saving_book.total_extra_savings
      
      difference = @glm.group_loan_product.initial_savings
      
      (final_total_savings - @initial_total_savings).should == @glm.group_loan_product.initial_savings
      (final_compulsory_savings - @initial_compulsory_savings).should == @glm.group_loan_product.initial_savings
      (final_extra_savings - @initial_extra_savings).should == BigDecimal("0")
      # the difference is the initial savings
    end
  end
end