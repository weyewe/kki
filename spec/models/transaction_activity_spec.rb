require 'spec_helper'

describe TransactionActivity do 
  before(:each) do 
    
    # how to prevent  double factories creation?
    # now , we are using the basic shite -> find it in db. if exists, use the one in DB
    # is there something like  FactoryGirl.find_or_create(:factory_name) << find this out. 
    # Will solve the problem in beautiful manner
    
    
    # what am I worried about? 
    # double factory creation => in creating the office, we triggered :
    # =>    1. Regency (North Jakarta)
          # triggered jakarta_province
    # =>    2. Subdistrict (Cilincing) 
          # triggered north jakarta regency
    # by now, if we did something wrong, we will have: 2 north_jakarta_regency, 2 provinces, 2 islands 
    
    # in the group_loan_commune creation, we triggered:
    # =>  1. Village (Kalibaru)
          # kalibaru villages triggered Cilincing subdistrict
          # Cilincing subdistrict triggerd north jakarta regency
          # and so on
    # by now we have 1 kalibaru_village, 2 cilincing subdistricts
    #  3 north jakarta regencies, 3 provinces, 3 islands
    
    # FUCK
    
    # we need branch manager  DONE
    # we need loan officer   DONE
    # we need cashier   DONE 
    # we need field_worker   DONE 
    # we need group_loan  DONE
    
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
    
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
            :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id )
    # we need these members hooked to the group loan (group_loan_memberships)
    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
    end
    
    # we need group_loan_product x 3 , just for variations
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
    
    #assign the group_loan_product subcription 
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
    @members.each do |member|
       # randomized
      glm = GroupLoanMembership.find(:first, :conditions => {
        :member_id => member.id,
        :group_loan_id => @group_loan.id 
      })
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    
    #start the group loan (the approval cycle)
    @group_loan.execute_propose_finalization( @loan_officer )
    @group_loan.start_group_loan( @branch_manager )
    
    puts "At the end of the highest before block"
    
    puts "total villages : #{Village.count}"
    puts "total subdistricts: #{Subdistrict.count}"
    puts "total regencies: #{Regency.count}"
    puts "total provinces: #{Province.count}"
    puts "total island: #{Island.count}"
  end
  
  context "Setup Payment Transaction Activity" do 
    it "is paid by deducting the loan"
    it "can be in cash without loan deduction"
    it "can by paid without loan deduction, but the savings withdrawal can't exceed the member's total savings"
    # is there special rule applied with member's total_savings?
    it "is marked as the setup payment transaction "
  end
  
  context "Loan Disbursement Transaction Activity: group loan has been approved and 
          setup payment has been taken" do
    
    # clear the setup payment transaction( everyone decides to do setup payment using the loan)
    before(:each) do 
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
    
    # it 'is just playing around' do
    #   end
    
    it "will execute loan disbursement if the current_user role is cashier" do 
       member = @members[ rand(8) ]
       glm = GroupLoanMembership.find(:first, :conditions => {
         :member_id => member.id,
         :group_loan_id => @group_loan.id 
       })
       
       [@cashier, @field_worker, @branch_manager, @loan_officer].each do |employee|
         transaction = TransactionActivity.execute_loan_disbursement( glm , employee )
         if employee.has_role?(:cashier, employee.get_active_job_attachment)   
           transaction.should be_valid
         else
           transaction.should be_nil  #equal(nil)
         end
       end
     end
    
    it "won't execute the loan disbursement if there has been a previous loan disbursement for the same member" do 
      member = @members[ rand(8) ]
      glm = GroupLoanMembership.find(:first, :conditions => {
        :member_id => member.id,
        :group_loan_id => @group_loan.id 
      })
      
      
      transaction_1 = TransactionActivity.execute_loan_disbursement( glm , @cashier )
      transaction_1.should be_valid
      
      transaction_2 = TransactionActivity.execute_loan_disbursement( glm , @cashier  )
      transaction_2.should be_nil
    end
    
    context "post condition after the disbursement transaction activity (deduct loan amount case)" do
      before(:each) do 
        member = @members[ rand(8) ]
        @glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
          })

        @transaction_1_executed = TransactionActivity.execute_loan_disbursement( @glm , @cashier )
      end

      it "will deduct the disbursement amount if the deposit is done by 'loan deduction scheme'" do
        group_loan_product = @glm.group_loan_product 
        full_loan_amount  = group_loan_product.loan_amount
        setup_fee = group_loan_product.setup_payment_amount
      
        total_money_received_by_member = full_loan_amount - setup_fee
      
      # difference between equal and == 
      # equal is checking the object identity
      # == is checking the magnitude 
        puts "actual value is #{@transaction_1_executed.total_transaction_amount}"
        puts "expected value is #{total_money_received_by_member}"
        @transaction_1_executed.total_transaction_amount.should  ==  total_money_received_by_member 
      end

      it "will create 2 transaction entries: giving the full amount to the member, 
        and the member will return the one equal with setup amount " do
        @transaction_1_executed.transaction_case.should ==TRANSACTION_CASE[:loan_disbursement_with_setup_payment_deduction]             
        @transaction_1_executed.should have(2).transaction_entries 
      
      
        group_loan_product = @glm.group_loan_product 
        full_loan_amount  = group_loan_product.loan_amount
        setup_fee = group_loan_product.setup_payment_amount
      
        total_money_exchanging_hands = full_loan_amount - setup_fee
        
        
        # check the transaction entries case 
        deducted_loan_disbursement_count = 0 
        deduction_of_loan_disbursement_count = 0
        amount_of_deducted_loan_disbursement = BigDecimal("0")
        amount_of_loan_disbursement_deduction = BigDecimal('0')
        @transaction_1_executed.transaction_entries.each do  |t_entry|
          if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:total_loan_disbursement_amount]
            deducted_loan_disbursement_count += 1 
            ( total_money_exchanging_hands + setup_fee).should == t_entry.amount
          end
          if t_entry.transaction_entry_code == TRANSACTION_ENTRY_CODE[:setup_fee_deduction_from_disbursement_amount]
            deduction_of_loan_disbursement_count += 1 
            setup_fee.should == t_entry.amount
          end
        end
      
        deducted_loan_disbursement_count.should ==  1 
        deduction_of_loan_disbursement_count.should  == 1 
        @transaction_1_executed.total_transaction_amount.should  ==  total_money_exchanging_hands 
      end
    end
  end
  
  describe "Weekly Loan Payment Transaction Activity" do 
    context "basic payment" do
    end
    
    context "special payment" do
      context "savings only" do
      end
      context "structured multiple weeks payment" do
      end
      
      context "no payment declaration" do
      end
    end
  end
  
  describe "Backlog Payment Transaction Activity" do 
    context "basic single backlog payment" do
    end
    context "multiple backlog payments + structured" do
    end
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