require 'spec_helper'

describe GroupLoan do
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
    # we need these members hooked to the group loan (group_loan_memberships)
    
    
    
    
  end
  
  context "group loan creation" do
    it "must be created by loan_officer" do
      group_loan_params = {
        :name => "Awesome Group Loan"
      }
      group_loan = GroupLoan.create_group_loan_with_creator( group_loan_params,  @loan_officer)
      group_loan.should be_nil 
      
      group_loan = GroupLoan.create_group_loan_with_creator( group_loan_params,  @branch_manager)
      group_loan.should be_valid
      
      group_loan.creator.id.should == @branch_manager.id 
      group_loan.office_id.should == @office.id 
    end
    
  end
  
  context "group loan membership assignment" do 
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
               :commune_id => @group_loan_commune }, @branch_manager)
    end
    
    it "should create membership through group loan memberships" do
      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
      end
      
      @group_loan.should have(@members.count).members
      @group_loan.should have(@members.count).group_loan_memberships
    end
    
    
  end
  
  context "group loan proposal" do
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune }, @branch_manager)

      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
      end
    end
    
    it "can only be proposed if all member has been assigned group loan product" do
      GroupLoanAssignment.add_new_assignment(:field_worker, @group_loan, @field_worker)
      GroupLoanAssignment.add_new_assignment(:loan_inspector, @group_loan, @branch_manager)
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.is_proposed.should be_false 
      
      
      
      
      
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)

      #assign the group_loan_product subcription 
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
      @group_loan.group_loan_memberships.each do |glm|
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.is_proposed.should be_true
      
      
    end
    
    it "can only be proposed if all group loan product has equal duration" do
      GroupLoanAssignment.add_new_assignment(:field_worker, @group_loan, @field_worker)
      GroupLoanAssignment.add_new_assignment(:loan_inspector, @group_loan, @branch_manager)
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
      @group_loan_product_d = FactoryGirl.create(:group_loan_product_d)   # 10 weeks 

      #assign the group_loan_product subcription 
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
          @group_loan_product_c, @group_loan_product_d]
          
      count = 0 
      @group_loan.group_loan_memberships.each do |glm|
        if count == 0 
          GroupLoanSubcription.create_or_change( @group_loan_product_d.id  ,  glm.id  )
        else
          GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
        end
        count += 1 
      end
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.is_proposed.should be_false  
      
      @group_loan.group_loan_memberships.each do |glm|
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.is_proposed.should be_true
      
    end
    
     
  end
  
  context "group loan approval" do 
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune }, @branch_manager)

      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
      end
      
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
          @group_loan_product_c] 
          
      @group_loan.group_loan_memberships.each do |glm|
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      
      GroupLoanAssignment.add_new_assignment(:field_worker, @group_loan, @field_worker)
      GroupLoanAssignment.add_new_assignment(:loan_inspector, @group_loan, @branch_manager)
      
      # @group_loan.execute_propose_finalization( @loan_officer )
    end
    
    it "can only be approved if it has been proposed" do 
      @group_loan.start_group_loan( @branch_manager )
      @group_loan.is_started.should be_false 
    end
    it "can only be approved by branch_manager" do
      @group_loan.execute_propose_finalization( @loan_officer )
      
      @group_loan.start_group_loan( @loan_officer )
      @group_loan.is_started.should be_false
      
      @group_loan.start_group_loan( @branch_manager )
      @group_loan.is_started.should be_true
    end
  end
  
  context "financial_education lecture attendance finalization" do
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune }, @branch_manager)

      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
      end
      
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
          @group_loan_product_c] 
          
      @group_loan.group_loan_memberships.each do |glm|
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.start_group_loan( @branch_manager )
    end
    
    it "should only allow financial_education attendance finalization if the group_loan has been started " + 
      " all group loan membership's financial education attendance has been marked" do
      
      # @group_loan.finalize_attendance_marking_in_financial_education( @loan_officer )
    end
    
    
    it "can only be approved by loan inspector"
    
  end
  
  context "group loan disbursement attendance finalization" do
    it "should only allow group loan attendance finalization if the the financial lecture attendance has been finalized"
    it "can only be finalized if all member's attendance has been marked :present or absent.. no late"
  end
  
  context "group loan disbursement approval" do 
    it "should only allow group loan disbursement approval if:disbursement attendance approved" + 
        "and  all active group loan membership has received the loan disbursement"
  end
  
  context "group loan grace period start"  do
    it "should only allow group loan grace period start if group loan disbursement has been approved" + 
        " and all weekly meeting has been finalized"
  end
  
  context "group loan, default loan payment clearance" do
    it "should only allow default payment clearance if grace period has been ended"
  end
  
  
end