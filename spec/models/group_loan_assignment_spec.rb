require 'spec_helper'

describe GroupLoanAssignment do
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
    
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
            :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id, office_id: @office.id )
    # we need these members hooked to the group loan (group_loan_memberships)
    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
    end
    
    # we need group_loan_product x 3 , just for variations
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
    
    #assign the group_loan_product subcription 
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
    @group_loan.group_loan_memberships.each do |glm|
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
  end
  
  
  context "creation of group_loan_assignment" do
    it "should prevents double assignment with the same role" do
      initial_group_loan_assignment_count = GroupLoanAssignment.count 
      @group_loan.add_assignment(:loan_inspector, @branch_manager )
      final_group_loan_assignment_count = GroupLoanAssignment.count
      (final_group_loan_assignment_count - initial_group_loan_assignment_count).should == 1
      
      @group_loan.add_assignment(:loan_inspector, @branch_manager )
      latest_final_group_loan_assignment_count = GroupLoanAssignment.count
      (latest_final_group_loan_assignment_count - initial_group_loan_assignment_count).should == 1
    end
  end
  
  context "extracting previous information" do
    before(:each) do
      @group_loan.add_assignment(:loan_inspector, @branch_manager )
    end
    
    it "should extract the role previously assigned" do
      @group_loan.has_assigned_role?(:loan_inspector, @branch_manager).should be_true 
    end
    
  end
end
