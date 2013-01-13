require 'spec_helper'

describe GroupLoan do
  
  puts " I want to live forever\n"
  
  before(:each) do
    puts " In the before each"
    @office = FactoryGirl.create(:cilincing_office)
    @branch_manager_role = FactoryGirl.create(:branch_manager_role)
    @loan_officer_role = FactoryGirl.create(:loan_officer_role)
    @cashier_role = FactoryGirl.create(:cashier_role)
    @field_worker_role = FactoryGirl.create(:field_worker_role)
    puts "after creating the role"
    
    puts "office is oK " if not @office.nil?
    puts "branch manager  role is oK " if not @branch_manager_role.nil?
    puts "loan officer role  is oK " if not @loan_officer_role.nil?
    puts "cashier is role oK " if not @cashier_role.nil?
    puts "field worker  role is oK " if not @field_worker_role.nil?
    
  
    
    @branch_manager = @office.create_user( [@branch_manager_role],
      :email => 'branch_manager@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    
    puts "BM is in deep shit" if @branch_manager.nil?
    puts "The BM stat: #{@branch_manager}"
    
    puts "bm is ok" if not @branch_manager.nil? 
    
    
    @loan_officer = @office.create_user( [@loan_officer_role], 
      :email => 'loan_officer@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234'
    )
    
    puts "loan officer is ok" if not @loan_officer.nil?
    puts "Loan officer id = #{@loan_officer.id }"
    
    
    @cashier = @office.create_user( [@cashier_role], 
      :email => 'cashier@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    puts "cashier is ok" if not @cashier.nil?
     puts "cashier id = #{@cashier.id }"
    
    
    @field_worker = @office.create_user( [@field_worker_role], 
      :email => 'field_worker@gmail.com',
      :password => 'willy1234',
      :password_confirmation => 'willy1234' 
    )
    
    puts "field worker is ok" if not @field_worker.nil?
    puts "field worker id = #{@field_worker.id }"
    
    @group_loan_commune = FactoryGirl.create(:group_loan_commune)
    #this shit will trigger the creation of kalibaru village, cilincing subdistrict 
    
    # @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
    #          :commune_id => @group_loan_commune.id }, @branch_manager)
    
    # we need several members in a given commune   DONE 
    
    puts "group loan commune is OK" if not @group_loan_commune.nil?
    
    # puts "Loan officer id: #{@loan_officer.id}"
    #   puts "GroupLoan Commune id: #{@group_loan_commune.id}"
    #   puts "Office  id: #{@office.id}"
    #   
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
     
    
    
    puts "we are in the creation of seeds members. Total member #{@members.count}\n"*10
     
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
       :commune_id => @group_loan_commune.id }, @branch_manager)
       
       
    @members.each do |member|
      GroupLoanMembership.create_membership( @loan_officer, member, @group_loan)
    end
    
    @group_loan.add_assignment(:field_worker, @field_worker)
    @group_loan.add_assignment(:loan_inspector, @branch_manager)
    @group_loan_product_a = FactoryGirl.create(:group_loan_product_a)  # 5 weeks
    @group_loan_product_b = FactoryGirl.create(:group_loan_product_b)  # 5 weeks
    @group_loan_product_c = FactoryGirl.create(:group_loan_product_c)  # 5 weeks
    
    group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b,
        @group_loan_product_c]
        
        
    # create the subcription 
    @group_loan.group_loan_memberships.each do |glm|
      GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
    end
    
    
    # create the subgroup 
    sub_group_count = 2 
    SubGroup.set_sub_groups( @group_loan, sub_group_count )
    @first_sub_group = @group_loan.sub_groups[0]
    @second_sub_group =  @group_loan.sub_groups[1]
    
    # assign the member to the subgroup 
    
    count = 0 
    @members.each do |member|
      if count%2 == 0 
        @first_sub_group.add_member( member )
      elsif count%2 == 1 
        @second_sub_group.add_member( member )
      end
      count = count + 1 
    end
    
    
    # propose group loan start
    @group_loan.execute_propose_finalization( @loan_officer )
    
    # start group loan
    @group_loan.start_group_loan( @branch_manager )
    
    # financial education attendance marking
    
    # => mark the financial education attendance 
    @first_glm = @first_sub_group.group_loan_memberships.order("created_at ASC")[0]
    @second_glm = @second_sub_group.group_loan_memberships.order("created_at ASC")[0]
    @third_glm = @first_sub_group.group_loan_memberships.order("created_at ASC")[1]
    
    @group_loan.group_loan_memberships.each do |glm|
      if glm.id == @first_glm.id 
        glm.mark_financial_education_attendance( @field_worker, false , @group_loan  )
      else
        glm.mark_financial_education_attendance( @field_worker, true, @group_loan  )
      end
    end
    
    
    # => propose financial education finalization
    @group_loan.propose_financial_education_attendance_finalization( @field_worker) 
    
    # => finalize financial education attendance
    @group_loan.finalize_financial_attendance_summary(@branch_manager)
      
    @group_loan.reload   # refresh the data  from db
    @first_glm.reload
    @second_glm.reload
    @third_glm.reload 
    
    # 1 member is disqualified from group 1  -> didn't attend financial education 
    
    # loan disbursement attendance marking
    
    # => marking the loan disbursement attendance 
    @group_loan.membership_to_receive_loan_disbursement.each do |glm|
      if glm.id == @second_glm.id or glm.id == @third_glm.id
        glm.mark_loan_disbursement_attendance( @field_worker, false, @group_loan  ) 
      end
      
      if glm.id == @first_glm.id 
        next
      end
      
      glm.mark_loan_disbursement_attendance( @field_worker, true, @group_loan  )
    end
    
    # THIS IS THE LOGIC NOT CAPTURED  << no rule at all.. let it be. 
    # glm.declare_setup_payment_by_loan_deduction
    # @group_loan.execute_finalize_setup_fee_collection( @field_worker )
    # @group_loan.approve_setup_fee_collection( @cashier )
    
    # => propose loan disbursement attendance finalization
    @group_loan.propose_loan_disbursement_attendance_finalization(@field_worker)
    
    # do the actual disbursement 
    @group_loan.reload 
    # do the actual transaction 
    @group_loan.group_loan_memberships.each do |glm|
      # important.. by default, set it to deduct setup fee from laon disbursment 
      glm.deduct_setup_payment_from_loan = true
      glm.save 
      TransactionActivity.execute_loan_disbursement( glm , @field_worker )
      # the column has_received_disbursement is checked 
    end
    
    # => finalize loan disbursement attendance (+ field worker returning the $$$ )
    @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager )
    
    
    
    # 2 members are disqualified from group 2  -> didn't attend loan disbursement 
    # returning the money from the 2 members weren't attending the disbursement 
    
    # cashier approves loan disbursement 
    @group_loan.execute_finalize_loan_disbursement(@cashier)
    
    
  end # end of before(:each block)
  
  context "testing the post conditions" do
    it "should have 7 active members" do 
      @group_loan.active_group_loan_memberships.count.should == 7 
    end
    
    it "should have 9 members attending teh financial education" do
      @group_loan.membership_attending_financial_education.count.should == 9
    end
    
    it "should have 7 members attending the loan disbursement" do
      @group_loan.membership_attending_financial_education.count.should == 9
    end
    
    it "should return the loan disbursement of 2 members" do 
      @group_loan.membership_whose_loan_disbursement_must_be_returned_to_cashier.count.should == 2 
      
      total_disbursement_returned = BigDecimal("0")
      @group_loan.membership_whose_loan_disbursement_must_be_returned_to_cashier.each do |glm|
        glp = glm.group_loan_product
        total_disbursement_returned += glp.loan_amount - glp.setup_payment_amount
      end
      total_disbursement_returned.should == @group_loan.total_amount_to_be_returned_to_cashier
    end
    
    
    it "should produce default payment for all active member, not produce default payment for non active" do 
      @group_loan.active_group_loan_memberships.each do |glm|
        glm.default_payment.should be_valid 
      end
      
      @group_loan.non_active_group_loan_memberships.each do |glm|
        glm.default_payment.should be_nil 
      end
      
      
    end
    
  end # end of "testing the post conditions"  context 
  
  context "do payment of 1 week, introduce update. can it be updated?" do 
    before(:each) do
      @weekly_task = @group_loan.weekly_tasks.order("week_number ASC").first 
      @active_glm_list = @group_loan.active_group_loan_memberships
      @glm_list_length = @active_glm_list.length 
      # first_glm = normal -> normal 
      @first_glm = @active_glm_list[0]
    
      @extra_savings = BigDecimal("10000")
      @savings_withdrawal  = BigDecimal('0')
      @number_of_weeks = 1 
      @number_of_backlogs =  0 
      @cash_payment = @first_glm.group_loan_product.total_weekly_payment
      
      @first_transaction = TransactionActivity.create_generic_weekly_payment(
        @weekly_task, 
              @first_glm,
              @field_worker,
               @cash_payment  ,
              @savings_withdrawal, 
              @number_of_weeks,
              @number_of_backlogs,
              false
      )
      
      
      
      
      
       
      
      @active_glm_list[1..@glm_list_length-1].each do |glm|
        member =  glm.member  
        glp = glm.group_loan_product 
    
        #  mark member attendance  # the order doesn't matter 
        @weekly_task.mark_attendance_as_present( glm.member, @field_worker )
        
        # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
        cash_payment = glp.total_weekly_payment
        savings_withdrawal = BigDecimal("0")
        number_of_weeks = 1 
        number_of_backlogs = 0 
        a = TransactionActivity.create_generic_weekly_payment(
          @weekly_task, 
                glm,
                @field_worker,
                cash_payment,
                savings_withdrawal, 
                number_of_weeks,
                number_of_backlogs,
                false
        )
        
      end 
    end
    
    it "should finalize weekly payment with normal -> normal update " do 
     
      second_transaction = TransactionActivity.update_generic_weekly_payment(
        @weekly_task, 
        @first_glm,
        @field_worker,
        @cash_payment + @extra_savings ,
        @savings_withdrawal, 
        @number_of_weeks,
        @number_of_backlogs   
      )
      
      
      second_transaction.should be_valid 
         
          
      
      # FINALIZING THE WEEK
      # we want to test whether the finalization works fine with all the changes 
          
        @weekly_task.close_weekly_meeting(@field_worker)
        @weekly_task.close_weekly_payment( @field_worker )
        @weekly_task.approve_weekly_payment_collection( @cashier )
        
        @weekly_task.is_weekly_attendance_marking_done.should be_true 
        @weekly_task.is_weekly_payment_collection_finalized.should be_true 
        @weekly_task.is_weekly_payment_approved_by_cashier.should be_true        
    end # example case 'it should do transaction as normal' 
   
  end 
  
  context 'should ensure reversability between backlog payment and future payment' do
    before(:each) do 
      @weekly_task = @group_loan.weekly_tasks.order("week_number ASC").first 
      @active_glm_list = @group_loan.active_group_loan_memberships
      @glm_list_length = @active_glm_list.length 
      # first_glm = normal -> normal 
      @first_glm = @active_glm_list[0]
    
      @extra_savings = BigDecimal("10000")
      @savings_withdrawal  = BigDecimal('0')
      @number_of_weeks = 1 
      @number_of_backlogs =  0 
      
      
      
      @group_loan.active_group_loan_memberships.each do |glm|
        if glm.id == @first_glm.id 
          # declare no payment
          ActiveRecord::Base.transaction do
            TransactionActivity.create_savings_only_weekly_payment(
              @first_glm.member ,
              @weekly_task,
              @extra_savings,
              @field_worker ,
              false # revision transaction
            )
          end
        else
          @cash_payment = glm.group_loan_product.total_weekly_payment
           TransactionActivity.create_generic_weekly_payment(
            @weekly_task, 
                  glm,
                  @field_worker,
                   @cash_payment  ,
                  @savings_withdrawal, 
                  @number_of_weeks,
                  @number_of_backlogs,
                  false
          )
        end
      end 
      
      @weekly_task.close_weekly_meeting(@field_worker)
      @weekly_task.close_weekly_payment( @field_worker )
      @weekly_task.approve_weekly_payment_collection( @cashier ) 
      
      # create an independent payment 
      @independent_number_of_backlogs = 1 
      @independent_number_of_weeks = 0 
      @independent_savings_withdrawal = 0 
      @independent_cash = @first_glm.group_loan_product.total_weekly_payment
      @first_glm.reload 
      @first_glm.unpaid_backlogs.count.should ==1
      
      
      # do the next week's weekly payment  
      #  by now, he has extra savings:  @extra_savings = BigDecimal("10000")
      @second_weekly_task = @group_loan.weekly_tasks.order("week_number ASC")[1]
      
      
    end
     
    context 'should revert backlog payment if it is done ' do
      before(:each) do
        @new_cash_payment = @first_glm.group_loan_product.total_weekly_payment *  2  # paying for 2 weeks
        @new_number_of_weeks = 1 
        @new_number_of_backlogs = 1 
        @new_savings_withdrawal = BigDecimal('0')

        ActiveRecord::Base.transaction do
          @new_transaction = TransactionActivity.create_generic_weekly_payment(
            @second_weekly_task, 
            @first_glm,
            @field_worker,
            @new_cash_payment  ,
            @new_savings_withdrawal, 
            @new_number_of_weeks,
            @new_number_of_backlogs,
            false
          )
        end
      end
      
      it 'should have cleared the backlog payment' do
        @new_transaction.should be_valid  
        @first_glm.reload 
        @first_glm.unpaid_backlogs.count.should == 0 
      end
      
      it 'should revert the backlog payment if the weekly payment is updated' do
        @first_glm.reload
        TransactionActivity.update_generic_weekly_payment(
                @second_weekly_task, 
                @first_glm,
                @field_worker,
                @new_cash_payment,
                @new_savings_withdrawal, 
                @new_number_of_weeks,
                0  )
                
        @first_glm.reload
        @first_glm.unpaid_backlogs.count.should == 1  
      end
      
    end
    
    context 'should revert savings withdrawal' do 
      #  by now, he has extra savings:  @extra_savings = BigDecimal("10000")
      before(:each) do
        @first_glm.reload 
        @initial_compulsory_savings = @first_glm.member.saving_book.total_compulsory_savings 
        @initial_voluntary_savings = @first_glm.member.saving_book.total_extra_savings 
        
        @new_cash_payment = @first_glm.group_loan_product.total_weekly_payment *  2 -  @extra_savings # paying for 2 weeks
        @new_number_of_weeks = 1 
        @new_number_of_backlogs = 1 
        @new_savings_withdrawal = @extra_savings

        ActiveRecord::Base.transaction do
          @new_transaction = TransactionActivity.create_generic_weekly_payment(
            @second_weekly_task, 
            @first_glm,
            @field_worker,
            @new_cash_payment  ,
            @new_savings_withdrawal, 
            @new_number_of_weeks,
            @new_number_of_backlogs,
            false
          )
        end
      end
      
      it 'should reduce the voluntary savings by @extra_savings' do
        @first_glm.reload 
        @final_compulsory_savings = @first_glm.member.saving_book.total_compulsory_savings 
        @final_voluntary_savings = @first_glm.member.saving_book.total_extra_savings
        
        voluntary_savings_diff = (@final_voluntary_savings - @initial_voluntary_savings )
        voluntary_savings_diff.should == -1*@extra_savings 
      end
      
      it 'should increase the voluntary savings if the transaction is updated' do 
        @first_glm.reload 
        
        @initial_voluntary_savings =  @first_glm.member.saving_book.total_extra_savings 
        ActiveRecord::Base.transaction do
          @updated_transaction = TransactionActivity.update_generic_weekly_payment(
            @second_weekly_task, 
            @first_glm,
            @field_worker,
            @new_cash_payment + @extra_savings  ,
            BigDecimal('0'), 
            @new_number_of_weeks,
            @new_number_of_backlogs 
          )
        end
        @first_glm.reload 
        @final_compulsory_savings = @first_glm.member.saving_book.total_compulsory_savings 
        @final_voluntary_savings = @first_glm.member.saving_book.total_extra_savings
        
        voluntary_savings_diff = (@final_voluntary_savings - @initial_voluntary_savings )
        voluntary_savings_diff.should == @extra_savings
        
      end
      
    end
     
     
  end 
end