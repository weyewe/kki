require 'spec_helper'

describe TransactionActivity do 
  before(:each) do 
    # we need branch manager
    # we need loan officer
    # we need cashier
    # we need field_worker  
    # we need group_loan
    # we need group_loan_product x 3 
    # we need several members in a given commune 
    # we need these members hooked to the group loan (group_loan_memberships)
    # in some cases, we need to run it several weeks cycle 
  end
  
  describe "Setup Payment Transaction Activity" do 
    it "is paid by deducting the loan"
    it "can be paid without loan deduction"
    it "can by paid without loan deduction, but the savings withdrawal can't exceed the member's total savings"
    it "is marked as the setup payment transaction "
  end
  
  context "Loan Disbursement Transaction Activity: group loan has been approved and 
          setup payment has been taken" do
    
    before(:each) do 
      
      puts "#{User.count}"
      @cashier = FactoryGirl.create(:cashier)
      @loan_officer = FactoryGirl.create(:loan_officer)
      @field_worker = FactoryGirl.create(:field_worker)
      @branch_manager = FactoryGirl.create(:branch_manager)
      
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11" }, @branch_manager)
      # create a list of member for this group_loan, condition => in the same commune with group_loan
      puts "before the shite, total commune is #{Commune.count}"
      
      @commune = Factory.create(:group_loan_commune)
      @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
       commune_id: @commune.id )
      puts "after the shite, total commune is #{Commune.count}"
      # assign member to the group loan 
      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
      end
      
      # assign to the group loan product
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
      
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
      @members.each do |member|
         # randomized
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.start_group_loan( @branch_manager )
      
      # everyone declared to pay with the loan 
      @members.each do |member|
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        glm.declare_setup_payment_by_loan_deduction
      end
      
      @group_loan.execute_finalize_setup_fee_collection( @field_worker )
      @group_loan.approve_setup_fee_collection( @cashier )
    end
    
    it 'is just playing around' do
    end
    
    # it "will be executed if the current_user role is cashier" do 
    #   member = @members[ rand(8) ]
    #   glm = GroupLoanMembership.find(:first, :conditions => {
    #     :member_id => member.id,
    #     :group_loan_id => @group_loan.id 
    #   })
    #   
    #   [@cashier, @field_worker, @branch_manager, @loan_officer].each do |employee|
    #     transaction = TransactionActivity.execute_loan_disbursement( glm , employee )
        # if employee.has_role?(USER_ROLE[:cashier])    << fault! must be job attachment 
    #       transaction.should be_valid
    #     else
    #       transaction.should_not be_valid
    #     end
    #   end
    # end
    
    # it "won't be executed if there has been a previous loan disbursement for the same member" do 
    #   member = @members[ rand(8) ]
    #   glm = GroupLoanMembership.find(:first, :conditions => {
    #     :member_id => member.id,
    #     :group_loan_id => @group_loan.id 
    #   })
    #   
    #   
    #   transaction_1 = TransactionActivity.execute_loan_disbursement( glm , @cashier )
    #   transaction_1.should be_valid
    #   
    #   transaction_2 = TransactionActivity.execute_loan_disbursement( glm , @cashier  )
    #   transaction_2.should_not be_valid
    # end
    
    # context "post condition after the disbursement transaction activity (deduct loan amount case)" do
    #       before(:each) do 
    #         member = @members[ rand(8) ]
    #         @glm = GroupLoanMembership.find(:first, :conditions => {
    #           :member_id => member.id,
    #           :group_loan_id => @group_loan.id 
    #         })
    #         
    #         @transaction_1_executed = TransactionActivity.execute_loan_disbursement( @glm , @cashier )
    #       end
    #       
    #       it "will deduct the disbursement amount if the deposit is done by 'loan deduction scheme'"
    #         group_loan_product = @glm.group_loan_product 
    #         full_loan_amount  = group_loan_product.loan_amount
    #         setup_fee = group_loan_product.setup_payment_amount
    # 
    #         total_money_received_by_member = full_loan_amount - setup_fee
    # 
    #         @transaction_1_executed.total_transaction_amount.should equal( total_money_received_by_member ) 
    #       end
    #       
    #       it "will create 2 transaction entries: giving the full amount to the member, 
    #                     and the member will return the one equal with setup amount " do
    #         @transaction_1_executed.transaction_case.should equal( 
    #                         TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]   )            
    #         @transaction_1_executed.should have(2).transaction_entries 
    #         
    #         # check the transaction entries case 
    #         deducted_loan_disbursement_count = 0 
    #         deduction_of_loan_disbursement_count = 0
    #         amount_of_deducted_loan_disbursement = BigDecimal("0")
    #         amount_of_loan_disbursement_deduction = BigDecimal('0')
    #         @transaction_1_executed.transaction_entries.each do  |t_entry|
    #           if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:deducted_loan_disbursement]
    #             deducted_loan_disbursement_count += 1 
    #             amount_of_deducted_loan_disbursement = t_entry.amount
    #           end
    #           if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:deduct_setup_fee_from_loan_disbursement]
    #             deduction_of_loan_disbursement_count += 1 
    #             amount_of_loan_disbursement_deduction = t_entry.amount
    #           end
    #         end
    #         
    #         deducted_loan_disbursement_count.should equal(1)
    #         deduction_of_loan_disbursement_count.should equal(1)
    #         @transaction_1_executed.total_transaction_amount.should equal( amount_of_deducted_loan_disbursement )
    #       end
    #     end
  end
  
  describe "Weekly Loan Payment Transaction Activity" do 
    it "records principal, compulsory savings, and interest payment"
    it "has minimum amount of the group_loan_product minimum amount"
  end
  
  describe "Backlog Payment Transaction Activity" do 
    it "records the principal, compulsory savings, and interest payment"
    it "might contain the penalty payment for being late, in which the rule we haven't understood"
  end
  
  it "is storing reference to the loan type, either group_loan or backlog payment, or single loan"
  it "has loan amount that is equal to the amoung of money exchanging hands from member to employee or vice versa"
  it "won't create double transaction activities "
  
  describe "Group Loan Default Resolution Transaction Activity" do
    it 'records the payment from all member, the minimum denomination is 500 rupiah (up rounded)'
    it "records the excess due to rounding as rounding payment"
  end
end