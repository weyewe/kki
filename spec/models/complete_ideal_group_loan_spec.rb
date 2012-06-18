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
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
     
    @group_loan = GroupLoan.create_group_loan_with_creator( {:name => "Group Loan 11",
       :commune_id => @group_loan_commune }, @branch_manager)
       
       
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
  
  context "start doing the weekly transaction. basic payment all the way" do 
    it "should do generic transaction as normal" do 
      
      # on loan disbursement finalization:
      # 1. create default payment for all active members 
      # 2. deduct the default payment on all transactions ( paying backlog or paying weekly payment)
      # 3. 

      # @weekly_task.close_weekly_meeting( current_user )
      # @weekly_task.close_weekly_payment( current_user )
      # where can we mark member attendnace?
      # 
      # for each member
      #   @weekly_task.mark_attendance_as_present( @member, current_user )
      #   @weekly_task.mark_attendance_as_late( @member, current_user )
      
      # if everyone is marked, or the unmarked will be declared as absent 
      #   @weekly_task.close_weekly_meeting( current_user )
      
      # if everyone has paid, or declared no payment, 
      # => @weekly_task.close_weekly_payment( current_user )
      
      # Then the cashier approves weekly payment
      # =>  @weekly_task.approve_weekly_payment_collection( current_user )
      
      # done? hahaha
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          member =  glm.member 
          saving_book = member.saving_book
          initial_total_savings                = saving_book.total 
          initial_extra_savings                = saving_book.total_extra_savings
          initial_compulsory_savings           = saving_book.total_compulsory_savings

          glp = glm.group_loan_product
          
          
          
          #  mark member attendance  # the order doesn't matter 
          weekly_task.mark_attendance_as_present( glm.member, @field_worker )
          # do payment 
          weekly_task = @group_loan.currently_executed_weekly_task
          
          puts "\n++++++++++ pre condition"
          puts "member_id : #{member.id}"
          
          puts "initial compulsory_savings: #{initial_compulsory_savings}"
          puts "the currently_executed_weekly_task : #{weekly_task.week_number}"
          # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
          cash_payment = glp.total_weekly_payment
          savings_withdrawal = BigDecimal("0")
          number_of_weeks = 1 
          number_of_backlogs = 0 
          a = TransactionActivity.create_generic_weekly_payment(
                  glm,
                  @field_worker,
                  cash_payment,
                  savings_withdrawal, 
                  number_of_weeks,
                  number_of_backlogs
          )
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
          
          puts "final compulsory_savings: #{final_compulsory_savings}"
          puts "\n******THE ANALYTICS"
          puts "glp min_savings : #{glp.min_savings}"
          puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
          puts "diff extra_savings: #{diff_extra_savings.to_i}"
          puts "The amount of diff for member #{member.id}: #{diff}"
          
          
          puts "transaction validity"
          a.should be_valid 
          a.transaction_entries.each do |te|
            puts "#{te.inspect}"
            puts "#{te.amount.to_i}"
          end
          
          
          puts "~~~~~ the assertion"
          diff.should == glp.min_savings
          diff_compulsory_savings.to_i.should == glp.min_savings.to_i
          diff_extra_savings.should == BigDecimal("0")
          
          
          
        end
        weekly_task.close_weekly_meeting(@field_worker)
        weekly_task.close_weekly_payment( @field_worker )
        weekly_task.approve_weekly_payment_collection( @cashier )
        
        weekly_task.is_weekly_attendance_marking_done.should be_true 
        weekly_task.is_weekly_payment_collection_finalized.should be_true 
        weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
      end
      
      # now is the time to close the group loan
      # close by branch manager -> if all weekly payments has been approved by cashier 
      # on close: execute the default payment.. if there is unpaid loan, will be deducted from compulsory savings by the responsible member
      # if there is remaining loan, deduct 50% from the non default member in the sub group, 50% from all non default member in the group 
      # then, after this deduction, migrate compulsory savings to extra savings 
      
      
      # @group_loan.generate_default_payments(@branch_manager) 
      # auto generated on loan disbursement finalization 
      
      @group_loan.is_closed.should be_false
      # not closed yet 
      
      
      # => DEFAULT PAYMENT RESOLUTION
      # =>  1. Standard algorithm
            # => deduct all backlogs (principal + interest, without compulsory savings) with member's compulsory savings
              # => if the compulsory savings is not enough, distribute it to the sub group and group non defaultees-> 50% - 50% 
      # =>  2. Custom value. Post deduction, non defaultee decide their contribution 
              # => due to the nature of 50% subgroup, it might lead to big amount. 
              #   solution -> non defaultee decide on their own about the concept of fairness 
              # can't change the amount of the defaultee compulsory savings deduction. but, the non defaultee's contribution
              # => can be changed
      @group_loan.reload
      @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
      @group_loan.reload
      @group_loan.execute_default_payment_execution( @cashier ) 
      
      # default payment deduction 
      
      @group_loan.active_group_loan_memberships.each do |glm|
        puts "Checking member #{glm.member_id}"
        
        
        default_payment = glm.default_payment
        default_payment.amount_to_be_paid.should == BigDecimal("0")
        default_payment.total_amount.should == BigDecimal("0")
      end
      
      
      
      # check the amount of compulsory savings 
      # cross check with manual calculation
      @group_loan.reload
      extra_savings_before_group_loan_close_array  = [] 
      expected_difference_in_extra_savings_after_group_loan_close_array = [] 
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        total_actual_compulsory_savings = glm.member.saving_book.total_compulsory_savings 
        expected = BigDecimal("0")
        expected += glm.group_loan_product.initial_savings
        
        expected += glm.group_loan.total_weeks * glm.group_loan_product.min_savings
        
        puts "The initial savings: #{glm.group_loan_product.initial_savings.to_i}"
        puts "expected = #{expected.to_i}"
        puts "actual = #{total_actual_compulsory_savings.to_i}"
        total_actual_compulsory_savings.should == expected
        extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
        expected_difference_in_extra_savings_after_group_loan_close_array << expected 
      end
      
      
      
      
      puts "gonna close group loan"
      @group_loan.close_group_loan(@branch_manager)
      # on  group loan close: migrate the $$$ from compulsory savings associated with this group loan 




      @group_loan.is_closed.should be_true 
      
      @group_loan.reload 
      
      # test the migration from compulsory savings to the shite savings 
      # => 2 arrays as theck.. 
      # extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
      # expected_difference_in_extra_savings_after_group_loan_close_array << expected
      count = 0 
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        final_extra_savings = glm.member.saving_book.total_extra_savings 
        
        diff = final_extra_savings - extra_savings_before_group_loan_close_array[count]
        glp = glm.group_loan_product
        
        
        puts "initial_savings: #{glp.initial_savings}"
        puts "compulsory_savings : #{glp.min_savings}" 
        puts "total_weeks: #{glm.group_loan.total_weeks}"
        puts "initial extra savings: #{extra_savings_before_group_loan_close_array[count]}"
        puts "final compulsory savings: #{glm.member.saving_book.total_compulsory_savings}"
        puts "final extra savings: #{final_extra_savings}"
        puts "actual diff = #{diff}"
        puts "expected diff = #{expected_difference_in_extra_savings_after_group_loan_close_array[count]}"
        
        diff.should == expected_difference_in_extra_savings_after_group_loan_close_array[count]
        
        count += 1 
        
        # testing that glm is deactivated
        glm.is_active.should be_false 
        glm.deactivation_case.should == GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
      end
       
       
       #  By now, the ideal case id done...... satisfactory, recorded all money coming in, and the source
       
      # in the custom case 
      # @group_loan.propose_custom_default_payment_execution( @field_worker, glm_and_custom_amount_pair ) 
      # verify that the custom amount < member compulsory savings 
      # @group_loan.execute_custom_default_payment_execution( @cashier ) 
      
      
      
      
      # test: paying unpaid backlogs in the grace period -> another transaction.. we haven't created it 
      # another example 
      
      # test: no transaction takes place -> no default 
      # test: all default payments end up with 0 amount 
      
    end # example case 'it should do transaction as normal'
    
    it "should do the realistic case #1: unpaid backlogs during the grace period, but cleared all" do
      
      # strategy: pick one member who doesn't pay all the way.
      
      # after the last week, do the payment -> create one 
      
      # @weekly_task.create_weekly_payment_declared_as_no_payment(@member)
      @first_glm = @group_loan.active_group_loan_memberships.first 
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          if glm.id == @first_glm.id 
            weekly_task.create_weekly_payment_declared_as_no_payment( glm.member )
            next
          end
          
          
          member =  glm.member 
          saving_book = member.saving_book
          initial_total_savings                = saving_book.total 
          initial_extra_savings                = saving_book.total_extra_savings
          initial_compulsory_savings           = saving_book.total_compulsory_savings

          glp = glm.group_loan_product
          
          
          
          #  mark member attendance  # the order doesn't matter 
          weekly_task.mark_attendance_as_present( glm.member, @field_worker )
          # do payment 
          weekly_task = @group_loan.currently_executed_weekly_task
          
          puts "\n++++++++++ pre condition"
          puts "member_id : #{member.id}"
          
          puts "initial compulsory_savings: #{initial_compulsory_savings}"
          puts "the currently_executed_weekly_task : #{weekly_task.week_number}"
          # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
          cash_payment = glp.total_weekly_payment
          savings_withdrawal = BigDecimal("0")
          number_of_weeks = 1 
          number_of_backlogs = 0 
          a = TransactionActivity.create_generic_weekly_payment(
                  glm,
                  @field_worker,
                  cash_payment,
                  savings_withdrawal, 
                  number_of_weeks,
                  number_of_backlogs
          )
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
          
          puts "final compulsory_savings: #{final_compulsory_savings}"
          puts "\n******THE ANALYTICS"
          puts "glp min_savings : #{glp.min_savings}"
          puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
          puts "diff extra_savings: #{diff_extra_savings.to_i}"
          puts "The amount of diff for member #{member.id}: #{diff}"
          
          
          puts "transaction validity"
          a.should be_valid 
          a.transaction_entries.each do |te|
            puts "#{te.inspect}"
            puts "#{te.amount.to_i}"
          end
          
          
          puts "~~~~~ the assertion"
          diff.should == glp.min_savings
          diff_compulsory_savings.to_i.should == glp.min_savings.to_i
          diff_extra_savings.should == BigDecimal("0")
          
          
          
        end
        weekly_task.close_weekly_meeting(@field_worker)
        weekly_task.close_weekly_payment( @field_worker )
        weekly_task.approve_weekly_payment_collection( @cashier )
        
        weekly_task.is_weekly_attendance_marking_done.should be_true 
        weekly_task.is_weekly_payment_collection_finalized.should be_true 
        weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
      end
      
      
      closing_result = @group_loan.close_group_loan(@branch_manager)
      closing_result.should be_nil
      
      #now we are in the grace period
      # do the grace period transaction
      
      cash_value = @first_glm.group_loan_product.grace_period_weekly_payment
      savings_withdrawal  = BigDecimal("0")
      
      number_of_weeks_1 = @group_loan.total_weeks + 1 
      result_1  = TransactionActivity.create_generic_grace_period_payment(
              @first_glm,
              @field_worker ,
              cash_value*number_of_weeks_1,
              savings_withdrawal,  
              number_of_weeks_1 )  # it will always paying the backlog. nothing else # no compulsory savings
        
      result_1.should be_nil 
      
      number_of_weeks_2 = @group_loan.total_weeks 
      
      result_2 =  TransactionActivity.create_generic_grace_period_payment(
              @first_glm,
              @field_worker ,
              cash_value*number_of_weeks_2,
              savings_withdrawal,  
              number_of_weeks_2)
              
      result_2.should  be_valid 
      
      result_2.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_principal]).count.should == number_of_weeks_2
      result_2.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_interest]).count.should == number_of_weeks_2
      
      
      # execute default loan payment
      
      @group_loan.reload
      @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
      @group_loan.reload
      @group_loan.execute_default_payment_execution( @cashier ) 
      
      # default payment deduction 
      
      @group_loan.active_group_loan_memberships.each do |glm|
        puts "Checking member #{glm.member_id}"
        
        
        default_payment = glm.default_payment
        default_payment.amount_to_be_paid.should == BigDecimal("0")
        default_payment.total_amount.should == BigDecimal("0")
      end
      # line 354
      
      
      @group_loan.reload
      extra_savings_before_group_loan_close_array  = [] 
      expected_difference_in_extra_savings_after_group_loan_close_array = [] 
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        total_actual_compulsory_savings = glm.member.saving_book.total_compulsory_savings 
        expected = BigDecimal("0")
        expected += glm.group_loan_product.initial_savings
        
        
        expected += glm.weekly_payments_paid_during_active_period *  glm.group_loan_product.min_savings
  
        
        
        
        
        puts "The initial savings: #{glm.group_loan_product.initial_savings.to_i}"
        puts "expected = #{expected.to_i}"
        puts "actual = #{total_actual_compulsory_savings.to_i}"
        total_actual_compulsory_savings.should == expected
        extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
        expected_difference_in_extra_savings_after_group_loan_close_array << expected 
      end
      
      
      
      @group_loan.close_group_loan(@branch_manager)
      # on  group loan close: migrate the $$$ from compulsory savings associated with this group loan 
      @group_loan.is_closed.should be_true 
      # @group_loan.reload 
      
      
      # # test the migration from compulsory savings to the extra savings s
      # # => 2 arrays as theck.. 
      # # extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
      # # expected_difference_in_extra_savings_after_group_loan_close_array << expected
      count = 0 
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        final_extra_savings = glm.member.saving_book.total_extra_savings 
        
        diff = final_extra_savings - extra_savings_before_group_loan_close_array[count]
        glp = glm.group_loan_product
        
        
        puts "initial_savings: #{glp.initial_savings}"
        puts "compulsory_savings : #{glp.min_savings}" 
        puts "total_weeks: #{glm.group_loan.total_weeks}"
        puts "initial extra savings: #{extra_savings_before_group_loan_close_array[count]}"
        puts "final compulsory savings: #{glm.member.saving_book.total_compulsory_savings}"
        puts "final extra savings: #{final_extra_savings}"
        puts "actual diff = #{diff}"
        puts "expected diff = #{expected_difference_in_extra_savings_after_group_loan_close_array[count]}"
        
        diff.should == expected_difference_in_extra_savings_after_group_loan_close_array[count]
        
        count += 1 
        
        # testing that glm is deactivated
        glm.is_active.should be_false 
        glm.deactivation_case.should == GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
      end
  
      puts "**********!!!!!!!!!!!^^^^^^^^^^^^%%%%%all shite is done\n"*10
    end
    
    
    
    it "should do the realistic case #1b: unpaid backlogs during the grace period, but cleared all" do
      
      # strategy: pick one member who doesn't pay all the way.
      
      # after the last week, do the payment -> create one 
      
      # @weekly_task.create_weekly_payment_declared_as_no_payment(@member)
      @first_glm = @group_loan.active_group_loan_memberships.first 
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          if glm.id == @first_glm.id   and [1,2,3].include?(weekly_task.week_number)
            # mark attendance 
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            # decide on the payment 
            weekly_task.create_weekly_payment_declared_as_no_payment( glm.member )
            next
          end
          
          
          member =  glm.member 
          saving_book = member.saving_book
          initial_total_savings                = saving_book.total 
          initial_extra_savings                = saving_book.total_extra_savings
          initial_compulsory_savings           = saving_book.total_compulsory_savings

          glp = glm.group_loan_product
          
          
          
          #  mark member attendance  # the order doesn't matter 
          weekly_task.mark_attendance_as_present( glm.member, @field_worker )
          # do payment 
          weekly_task = @group_loan.currently_executed_weekly_task
          
          puts "\n++++++++++ pre condition"
          puts "member_id : #{member.id}"
          
          puts "initial compulsory_savings: #{initial_compulsory_savings}"
          puts "the currently_executed_weekly_task : #{weekly_task.week_number}"
          # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
          cash_payment = glp.total_weekly_payment
          savings_withdrawal = BigDecimal("0")
          number_of_weeks = 1 
          number_of_backlogs = 0 
          a = TransactionActivity.create_generic_weekly_payment(
                  glm,
                  @field_worker,
                  cash_payment,
                  savings_withdrawal, 
                  number_of_weeks,
                  number_of_backlogs
          )
          
          a.should be_valid 
          
          if glm.id == @first_glm.id
            puts "%%%%%%% this is the first glm. transaction_activity: #{a.transaction_case}\n"*5
          end
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
          
          puts "final compulsory_savings: #{final_compulsory_savings}"
          puts "\n******THE ANALYTICS"
          puts "glp min_savings : #{glp.min_savings}"
          puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
          puts "diff extra_savings: #{diff_extra_savings.to_i}"
          puts "The amount of diff for member #{member.id}: #{diff}"
          
          
          puts "transaction validity"
          a.should be_valid 
          a.transaction_entries.each do |te|
            puts "#{te.inspect}"
            puts "#{te.amount.to_i}"
          end
          
          
          puts "~~~~~ the assertion"
          diff.should == glp.min_savings
          diff_compulsory_savings.to_i.should == glp.min_savings.to_i
          diff_extra_savings.should == BigDecimal("0")
          
          
          
        end
        weekly_task.close_weekly_meeting(@field_worker)
        weekly_task.close_weekly_payment( @field_worker )
        weekly_task.approve_weekly_payment_collection( @cashier )
        
        weekly_task.is_weekly_attendance_marking_done.should be_true 
        weekly_task.is_weekly_payment_collection_finalized.should be_true 
        weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
      end
      
      
      # over here, default payments are created 
      
      closing_result = @group_loan.close_group_loan(@branch_manager)
      closing_result.should be_nil
      
      #now we are in the grace period
      # do the grace period transaction
      
      cash_value = @first_glm.group_loan_product.grace_period_weekly_payment
      savings_withdrawal  = BigDecimal("0")
      
      number_of_weeks_1 = @group_loan.total_weeks + 1 
      result_1  = TransactionActivity.create_generic_grace_period_payment(
              @first_glm,
              @field_worker ,
              cash_value*number_of_weeks_1,
              savings_withdrawal,  
              number_of_weeks_1 )  # it will always paying the backlog. nothing else # no compulsory savings
        
      result_1.should be_nil 
      
      number_of_weeks_2 =  @group_loan.total_weeks  - 2
      
      @first_glm.unpaid_backlogs.count.should == number_of_weeks_2 
      # i want to know the memberpayment
      
      result_2 =  TransactionActivity.create_generic_grace_period_payment(
              @first_glm,
              @field_worker ,
              cash_value*number_of_weeks_2,
              savings_withdrawal,  
              number_of_weeks_2)
              
      result_2.should  be_valid 
      
      result_2.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_principal]).count.should == number_of_weeks_2
      result_2.transaction_entries.where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:weekly_interest]).count.should == number_of_weeks_2
      
      
      @first_glm.unpaid_backlogs.count.should == 0
      
      # execute default loan payment
      
      @group_loan.reload
      @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
      @group_loan.reload
      @group_loan.execute_default_payment_execution( @cashier ) 
      
      # default payment deduction 
      
      @group_loan.active_group_loan_memberships.each do |glm|
        puts "Checking member #{glm.member_id}"
        
        default_payment = glm.default_payment
        
        if glm.id == @first_glm.id 
          puts "This is the first glm"
          puts "amount to be paid: #{default_payment.amount_to_be_paid}"
          puts "total amount: #{default_payment.total_amount}"
          
          puts "default_payment.inspect: #{default_payment.inspect}"
        end
        
        
        default_payment.amount_to_be_paid.should == BigDecimal("0")
        default_payment.total_amount.should == BigDecimal("0")
        
        default_payment.amount_of_compulsory_savings_deduction.should == BigDecimal("0")
        default_payment.amount_to_be_shared_with_non_defaultee.should == BigDecimal("0")
        
       
      end
      # line 354
      
      
      @group_loan.reload
      extra_savings_before_group_loan_close_array  = [] 
      expected_difference_in_extra_savings_after_group_loan_close_array = [] 
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        total_actual_compulsory_savings = glm.member.saving_book.total_compulsory_savings 
        expected = BigDecimal("0")
        expected += glm.group_loan_product.initial_savings
        
        
        expected += glm.weekly_payments_paid_during_active_period *  glm.group_loan_product.min_savings
  
        if glm.id == @first_glm.id
          puts "~!@___________ total weekly payments paid during active period: #{glm.weekly_payments_paid_during_active_period}\n"*10
        end
        
        
        
        puts "The initial savings: #{glm.group_loan_product.initial_savings.to_i}"
        puts "expected = #{expected.to_i}"
        puts "actual = #{total_actual_compulsory_savings.to_i}"
        total_actual_compulsory_savings.should == expected
        extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
        expected_difference_in_extra_savings_after_group_loan_close_array << expected 
      end
      
      
      
      
      
      
      # # test the migration from compulsory savings to the extra savings s
      # # => 2 arrays as theck.. 
      # # extra_savings_before_group_loan_close_array <<  glm.member.saving_book.total_extra_savings 
      # # expected_difference_in_extra_savings_after_group_loan_close_array << expected
      
      active_glm_array = @group_loan.active_group_loan_memberships.order("created_at ASC")
      
      @group_loan.close_group_loan(@branch_manager)
      # on  group loan close: migrate the $$$ from compulsory savings associated with this group loan 
      @group_loan.is_closed.should be_true 
      # @group_loan.reload
      
      puts "GONNAN PUT THE RECAP \n"*10
      count = 0 
      active_glm_array.each do |glm|
        final_extra_savings = glm.member.saving_book.total_extra_savings 
        
        diff = final_extra_savings - extra_savings_before_group_loan_close_array[count]
        glp = glm.group_loan_product
        
        if glm.id == @first_glm.id 
          puts "This is the first glm =======>>>> TADAAA!"
        end
        
        puts "glp.initial_savings: #{glp.initial_savings}"
        puts "glp.compulsory_savings : #{glp.min_savings}" 
        puts "total_weeks: #{glm.group_loan.total_weeks}"
        puts "initial extra savings: #{extra_savings_before_group_loan_close_array[count]}"
        puts "final compulsory savings: #{glm.member.saving_book.total_compulsory_savings}"
        puts "final extra savings: #{final_extra_savings}"
        puts "actual diff in extra savings= #{diff}"
        puts "expected diff in extra savings = #{expected_difference_in_extra_savings_after_group_loan_close_array[count]}"
        
        diff.should == expected_difference_in_extra_savings_after_group_loan_close_array[count]
        
        
        puts "counter value = #{count}"
        count += 1 
        
        # testing that glm is deactivated
        glm.is_active.should be_false 
        glm.deactivation_case.should == GROUP_LOAN_MEMBERSHIP_DEACTIVATE_CASE[:group_loan_is_closed]
      end
  
      puts "**********!!!!!!!!!!!^^^^^^^^^^^^%%%%%SHIT 1b  is done.. gonna close \n"*10
      
      



    end
    
    # done in complete_unideal_group_loan_spec.rb
    # it "should do the final case #2: unpaid backlogs at the end of grace period. distribute the pain to all non defaultee members" do
    #   # strategy: take 50% out from each subgroup. paying only once. The rest is shared among other members. hehe.. looks good
    #   
    #   defaultee_glm_list = @first_sub_group[0..1] + @second_sub_group[0..1]
    #   defaultee_glm_id_list = @defaultee_glm_list.collect {|x| x.id }
    #   
    #   
    #   
    #   
    # end
    # 
    # 
    # it "should do the final case #3: unpaid backlogs at the end of grace period. distribute the pain to all non defaultee members. CUSTOM-schema" do
    #   puts " SHIT SHIT "
    # end
    
    
   
  end
  
  
  context "close the group loan"
  
  context "check the post condition of the closing"
  
  # to be tested
  
  
  # =>  create the default payment for 7 active group members
  # =>  create the weekly tasks 
  # => start doing weekly payment 
  # => at the end, no backlog payment
  # => propose finalization to branch manager 
  # => branch manager close group loan  
        # => compulsory payment is converted to extra payment 
  # => done, everyone is happy. 
  
  # => request for withdrawal?  <<< how should this shit work? 
  
  
end