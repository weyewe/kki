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
    #          :commune_id => @group_loan_commune.id }, @branch_manager)
    
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
               :commune_id => @group_loan_commune.id }, @branch_manager)
    end
    
    it "should create membership through group loan memberships" do
      
      if @group_loan.nil?
        puts "------------------The group loan is nil"
      else
        puts "------------------Hahaha, the group loan is not nil"
      end
      
      if @loan_officer.nil?
        puts "------------------The loan officer is nil"
      else
        puts "------------------Hahaha, the loan officer is not nil"
      end
      
      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
      end
      
      @group_loan.should have(@members.count).members
      @group_loan.should have(@members.count).group_loan_memberships
    end
    
    
  end
  
  context "group loan proposal" do
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune.id }, @branch_manager)

      @members.each do |member|
        GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
      end
    end
    
    it "can only be proposed if all member has been assigned group loan product" do
 
      
      @group_loan.add_assignment(:field_worker, @field_worker)
      @group_loan.add_assignment(:loan_inspector, @branch_manager)
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
      
      puts "--------- unassigneed member : #{@group_loan.unassigned_members.count}"
      puts "--------equal loan duration: #{@group_loan.equal_loan_duration}"
      puts "product_a duration = #{@group_loan_product_a.total_weeks}"
      puts "group_loan_product_b duration = #{@group_loan_product_b.total_weeks}"
      puts "group_loan_product_c duration = #{@group_loan_product_c.total_weeks}"
      
      puts "all group loan product used: #{@group_loan.all_group_loan_products_used.count}"
      
      puts "group_loan_membership1 : #{@group_loan.group_loan_memberships.first.group_loan_subcription}}"
      @group_loan.add_assignment(:field_worker, @field_worker)
      @group_loan.add_assignment(:loan_inspector, @branch_manager)
      
      
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.is_proposed.should be_true
      
      
    end
    
    it "can only be proposed if all group loan product has equal duration" do

      @group_loan.add_assignment(:field_worker, @field_worker)
      @group_loan.add_assignment(:loan_inspector, @branch_manager)
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
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune.id }, @branch_manager)

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
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune.id }, @branch_manager)

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
    end
    
    
    it " can only be proposed if all financial education attendance has truth value ( true or false )" do
      
      first_group_loan_membership = @group_loan.group_loan_memberships.first 
      
      @group_loan.group_loan_memberships.each do |glm|
        if first_group_loan_membership.id == glm.id 
          next 
        end
        
        glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
      end
      
      
      # # it has to be proposed by the field worker. if it is not proposed, should be false 
      #      @group_loan.finalize_financial_attendance_summary(@branch_manager)
      #      @group_loan.is_financial_education_attendance_done.should be_false 
      
      @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
      puts "The first_glm attendance = #{first_group_loan_membership.is_attending_financial_lecture} "
      @group_loan.financial_education_finalization_proposed.should be_false 
      
      first_group_loan_membership.mark_financial_education_attendance( @field_worker, true, @group_loan  )
      
      @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
      @group_loan.financial_education_finalization_proposed.should be_true 

           #  
           # @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
           # @group_loan.finalize_financial_attendance_summary(@branch_manager)
           # 
           # @group_loan.is_financial_education_attendance_done.should be_true
    end
    
    it "can only be proposed by field worker (financial_education_attendance finalization)" do 
      
      @group_loan.group_loan_memberships.each do |glm|
        glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
      end
      
      
      @group_loan.propose_financial_education_attendance_finalization( @branch_manager) 
      @group_loan.financial_education_finalization_proposed.should be_false 
      
      @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
      @group_loan.financial_education_finalization_proposed.should be_true
      
    end
    
    
    context "after financial education attendance proposal" do
      
     
     it "can only be finalized by loan inspector"  do
       @group_loan.group_loan_memberships.each do |glm|
         glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
       end
       
       @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
       
       @group_loan.finalize_financial_attendance_summary(@field_worker)
       @group_loan.is_financial_education_attendance_done.should be_false 
       
       @group_loan.finalize_financial_attendance_summary(@branch_manager)
       @group_loan.is_financial_education_attendance_done.should be_true 
     end
     
     
     # shouldn't this be tested in group loan membership? yes, it should be located over there
     it "can be edited by the loan inspector, the final financial education attendance is the loan-inspector's version" do
       @group_loan.group_loan_memberships.each do |glm|
         glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
       end

       @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
       
       @group_loan.group_loan_memberships.each do |glm|
         glm.mark_final_financial_education_attendance(@branch_manager, false, @group_loan)
       end
       
       @group_loan.finalize_financial_attendance_summary(@branch_manager)
       
       @group_loan.group_loan_memberships.each do |glm|
         glm.final_financial_lecture_attendance.should == false 
       end
     end
     
     it "can be edited by the loan inspector, the final financial education attendance is the loan-inspector's version" do
        @group_loan.group_loan_memberships.each do |glm|
          glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
        end

        @group_loan.propose_financial_education_attendance_finalization( @field_worker) 

        @group_loan.group_loan_memberships[0..4].each do |glm|
          glm.mark_final_financial_education_attendance(@branch_manager, false, @group_loan)
        end

        @group_loan.finalize_financial_attendance_summary(@branch_manager)

        @group_loan.group_loan_memberships[0..4].each do |glm|
          glm.final_financial_lecture_attendance.should be_false
          glm.is_active.should be_false 
          glm.deactivation_case.should == GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_lecture_absent]
        end
        
        @group_loan.group_loan_memberships[5..7].each do |glm|
          glm.final_financial_lecture_attendance.should be_true
          glm.is_active.should be_true 
          glm.deactivation_case.should be_nil
        end
      end
      
      
      it "should produce the list of all member attending the financial education to the cashier, to prepare loan disbursement money" do
        @group_loan.group_loan_memberships.each do |glm|
          glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
        end

        @group_loan.propose_financial_education_attendance_finalization( @field_worker) 

        @group_loan.group_loan_memberships[0..4].each do |glm|
          glm.mark_final_financial_education_attendance(@branch_manager, false, @group_loan)
        end

        @group_loan.finalize_financial_attendance_summary(@branch_manager)
        
        @group_loan.membership_to_receive_loan_disbursement.count.should == 3 
        
        
        # @group_loan.list_of_membership_attending_the_financial_education == count 
      end
    end
  end
  
  context "group loan disbursement attendance finalization, 1 member absent in education, 2 members are absent on loan disbursement" do
    # it "should only allow group loan attendance finalization if the the financial lecture attendance has been finalized"
    # done in the group loan membership
    before(:each) do
      @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11", :commune_id => @group_loan_commune.id }, @branch_manager)

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
      @first_glm = @group_loan.group_loan_memberships[0]
      @second_glm = @group_loan.group_loan_memberships[1]
      @third_glm = @group_loan.group_loan_memberships[2]
      
      @group_loan.group_loan_memberships.each do |glm|
        if glm.id == @first_glm.id 
          glm.mark_financial_education_attendance( @field_worker, false , @group_loan  )
        else
          glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
        end
      end
      
      @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
      @group_loan.finalize_financial_attendance_summary(@branch_manager)
    end
    
    it " should give appropriate cash to field worker. assumption: loan amount deduction" do 
      total_amount_passed_to_field_worker = BigDecimal("0")
      
      @group_loan.membership_to_receive_loan_disbursement.each do |glm|
        glp = glm.group_loan_product
        total_amount_passed_to_field_worker += glp.loan_amount - glp.setup_payment_amount
      end
      
      total_amount_passed_to_field_worker.should == @group_loan.total_amount_passed_to_field_worker 
    end
    
    # then, do the loan disbursement attendance marking 
    # the logic is tested in the group_loan_membership_spec
    
    it "should return the appropriate cash to the cashier, depending on the attendance in loan disbursement" do
      
      @second_glm.mark_loan_disbursement_attendance( @field_worker, false, @group_loan  )
      @third_glm.mark_loan_disbursement_attendance( @field_worker, false, @group_loan  )
      
      puts "First glm id : #{@first_glm.id}"
      puts "Second glm id : #{@second_glm.id}"
      puts "Third glm id : #{@third_glm.id}"
      
      @group_loan.membership_to_receive_loan_disbursement.each do |glm|
        if glm.id == @second_glm.id or glm.id == @third_glm.id or @first_glm.id == glm.id 
          next
        end
        
        glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
        puts "marking disbursement attendance. glm id : #{glm.id}, attendance: #{glm.is_attending_loan_disbursement}"
      end
      
      @group_loan.propose_loan_disbursement_attendance_finalization(@field_worker)
      
      # FUCK, OBJECT MUST BE RELOADED! to by pass the buffered version
      @group_loan.reload 
      # do the actual transaction 
      @group_loan.group_loan_memberships.each do |glm|
        TransactionActivity.execute_loan_disbursement( glm , @field_worker )
        # the column has_received_disbursement is checked 
      end
      
      
      
      # will be finalized later,... that finalization will determine the money to be returned to the cashier 
      # what if the member rejected, cancel? no idea.. mark as absent ? corner cases, one in a million. can't be solved for now
      @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager )
      
      total_amount_to_be_returned = BigDecimal("0")
      total_amount_to_be_returned += @second_glm.group_loan_product.loan_amount -   @second_glm.group_loan_product.setup_payment_amount
      total_amount_to_be_returned += @third_glm.group_loan_product.loan_amount -   @third_glm.group_loan_product.setup_payment_amount
       
      total_amount_to_be_returned.should == @group_loan.total_amount_to_be_returned_to_cashier 
    end
    
    
    # then, the weekly transaction takes place. take notice -> the cashier must approve loan disbursement + money returned
    
    
    
    
    # it "can only be finalized if all the active member loan disbursement attendance has been marked" do
    #   @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager)
    #   @group_loan.is_loan_disbursement_attendance_done.should be_false
    #   
    #   
    #   count = 1
    #   
    #   @group_loan.active_group_loan_memberships.each do |glm|
    #     attendance = false
    #     if count%2 != 0 
    #       attendance = true 
    #     end
    #     count += 1 
    #     glm.mark_loan_disbursement_attendance( @field_worker, attendance, @group_loan  )
    #     glm.is_attending_loan_disbursement.should == attendance
    #   end
    #   
    #   
    #   @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager)
    #   @group_loan.is_loan_disbursement_attendance_done.should be_true 
    # end
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