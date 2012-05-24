require 'spec_helper'

describe GroupLoanMembership do
  before(:each) do
    @office = FactoryGirl.create(:cilincing_office)
    @koja_office = FactoryGirl.create(:koja_office)
    
    @branch_manager_role = FactoryGirl.create(:branch_manager_role)
    @loan_officer_role = FactoryGirl.create(:loan_officer_role)
    @cashier_role = FactoryGirl.create(:cashier_role)
    @field_worker_role = FactoryGirl.create(:field_worker_role)
    
    @branch_manager = @office.create_user( [@branch_manager_role],
      :email => 'branch_manager@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @koja_branch_manager = @koja_office.create_user(  [@branch_manager_role],
      :email => 'branch_manager_koja@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    
    @loan_officer = @office.create_user( [@loan_officer_role], 
      :email => 'loan_officer@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    @koja_loan_officer = @koja_office.create_user( [@loan_officer_role], 
      :email => 'loan_officer_koja@gmail.com',
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
    @different_subdistrict_commune = FactoryGirl.create(:different_subdistrict_commune)
    #this shit will trigger the creation of kalibaru village, cilincing subdistrict 
    
    # @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
    #          :commune_id => @group_loan_commune }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    @different_commune = FactoryGirl.create(:non_group_loan_commune)
    # 8 = number of member created
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id, office_id: @office.id )
    @different_commune_member = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 1, creator_id: @loan_officer.id, 
      commune_id: @different_commune.id, office_id: @office.id ).first
     
    @cilincing_member = @members.first 
    @cilincing_member_2 = @members.last
    @different_subdistrict_member = FactoryGirl.create(:non_cilincing_member, creator_id: @koja_loan_officer.id,
        commune_id: @different_subdistrict_commune.id , office_id: @koja_office.id)
    # we need these members hooked to the group loan (group_loan_memberships)
    group_loan_params = {
      :name => "Awesome Group Loan"
    }
    @cilincing_group_loan = GroupLoan.create_group_loan_with_creator( group_loan_params,  @branch_manager)
    @koja_group_loan = GroupLoan.create_group_loan_with_creator( group_loan_params,  @koja_branch_manager)
  end
  
  context "group loan membership creation" do
    it "can only create membership to the group loan from the same office" do
            # 
            # puts "cilincing member's office id : #{@cilincing_member.office_id}"
            # puts "cilincing member 2 's office id : #{@cilincing_member_2.office_id}"
            # puts "cilincing group loan's office id : #{@cilincing_group_loan.office_id}"
            # 
      
      glm_cilincing = GroupLoanMembership.create_membership( @loan_officer,
                                  @cilincing_member, @cilincing_group_loan)
                                  
      
      glm_cilincing.should be_valid 
      
      glm_cilincing_2 = GroupLoanMembership.create_membership( @loan_officer,
                                  @different_subdistrict_member, @cilincing_group_loan)
      glm_cilincing_2.should be_nil
    end
    
    it "should only create membership if the loan officer are registered at the same group loan office" do
      # puts "koja_loan_officer office_id = #{@koja_loan_officer.active_job_attachment.office_id}"
      #      puts "cilincing_group_loan office_id = #{@cilincing_group_loan.office_id}"
      glm_cilincing_2 = GroupLoanMembership.create_membership( @koja_loan_officer,
                                  @cilincing_member, @cilincing_group_loan)
      glm_cilincing_2.should be_nil
      
      glm_cilincing = GroupLoanMembership.create_membership( @loan_officer,
                                  @cilincing_member, @cilincing_group_loan)
                                  
      
      glm_cilincing.should be_valid 
    end
    
    it "will  accept member whose commune is not the same with this group loan's commune"  do  #this is the logic in group loan membership
      glm_cilincing_first_commune = GroupLoanMembership.create_membership( @loan_officer,
                                  @cilincing_member, @cilincing_group_loan)
      glm_cilincing_first_commune.should be_valid                            
                                  
      glm_cilincing_second_commune = GroupLoanMembership.create_membership( @loan_officer,
                                  @different_commune_member, @cilincing_group_loan)
      glm_cilincing_second_commune.should be_valid
      
    end
    
    context "two group loan running in parallel" do
      # the logic is not really clear over here
      # before(:each) do 
      #    # run the first group loan (started) 
      #    # assign all member
      #    @members.each do |member|
      #      GroupLoanMembership.create_membership( @loan_oficer, member, @cilincing_group_loan)
      #    end
      #    # assign the group_loan_assignment 
      #    GroupLoanAssignment.add_new_assignment(:field_worker, @cilincing_group_loan, @field_worker)
      #    GroupLoanAssignment.add_new_assignment(:loan_inspector, @cilincing_group_loan, @branch_manager)
      #    
      #    # assign the group loan product
      #    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
      #    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
      #    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
      # 
      #    #assign the group_loan_product subcription 
      #    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
      #    @cilincing_group_loan.group_loan_memberships.each do |glm|
      #      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      #    end
      #    
      #    @cilincing_group_loan.execute_propose_finalization( @loan_officer )
      #    
      #    # @cilincing
      #    # propose the group loan
      #    # start the group loan 
      #  end
      
      
      it "should not accept member with another on going group loan" do
        # @cilincing_group_loan        # 
                # @cilincing_group_loan.start_group_loan( @branch_manager )
                # group_loan_2 = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 2 "},  @branch_manager)
        
      end
      
      it "should auto disable the group_loan_membership, if the other group loan is started"
    end
    
  end
  
  context "marking compulsory attendance for financial education and loan disbursement" do
    
    before(:each) do 
   
      
      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_officer, member, @cilincing_group_loan)
      end
      # assign the group_loan_assignment 
      
      GroupLoanAssignment.add_new_assignment(:field_worker, @cilincing_group_loan, @field_worker)
      GroupLoanAssignment.add_new_assignment(:loan_inspector, @cilincing_group_loan, @branch_manager)

      # assign the group loan product
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)
      # 
      # #assign the group_loan_product subcription 
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
      @cilincing_group_loan.group_loan_memberships.each do |glm|
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end
      # 
      @cilincing_group_loan.execute_propose_finalization( @loan_officer )
      
      # @cilincing_group_loan.start_group_loan( @branch_manager )
      # @cilincing
      # propose the group loan
      # start the group loan 
    end
    
    
    it "should not mark financial education attendance if the group loan has not been started" do
      puts "We have added the GroupLoanAssignment"
      # GroupLoanAssignment.add_new_assignment(:field_worker, @cilincing_group_loan, @field_worker)
      # GroupLoanAssignment.add_new_assignment(:loan_inspector, @cilincing_group_loan, @branch_manager)
      puts "Total GroupLoanAssignment created: #{GroupLoanAssignment.count}"
      
        
      first_glm = @cilincing_group_loan.group_loan_memberships.first 
      first_glm.mark_financial_education_attendance(@branch_manager, true, @cilincing_group_loan  )
      first_glm.is_attending_financial_lecture.should be_nil

      @cilincing_group_loan.start_group_loan( @branch_manager )

      # first_glm.mark_financial_education_attendance( @branch_manager, true, @cilincing_group_loan  )
      #  first_glm.is_attending_financial_lecture.should be_true
      
    end
    
    it " should not mark loan disbursement attendance if the member were absent during the financial education"
  end
  

end