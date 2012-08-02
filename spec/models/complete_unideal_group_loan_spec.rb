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
    
    
    
    
  end # end of "testing the post conditions"  context 
  
  context "start doing the weekly transaction. basic payment all the way" do 
   
    
    it "should do the final case #2: unpaid backlogs at the end of grace period. distribute the pain to all non defaultee members" do
      # strategy: take 50% out from each subgroup. paying only once. The rest is shared among other members. hehe.. looks good
      
      
      
      defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
      defaultee_glm_id_list = defaultee_glm_list.collect {|x| x.id }
      puts "the list: #{defaultee_glm_id_list}"
      
      # now we have 4.. each of them only pay once for weekly payment
      
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          # present in the weekly meeting. declaring no payment 
          if defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
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
            weekly_task, 
                  glm,
                  @field_worker,
                  cash_payment,
                  savings_withdrawal, 
                  number_of_weeks,
                  number_of_backlogs
          )
          
          a.should be_valid 
          
      
          
          
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
          
          a.should be_valid 
      
          
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
      
      # after doing weekly payment cycle -> on the last weekly payment approval, 
      # default payments are created 
      
      closing_result = @group_loan.close_group_loan(@branch_manager)
      closing_result.should be_nil
     
      
      defaultee_glm_list.each do |glm|
        glm.reload
        glm.unpaid_backlogs.count.should == @group_loan.total_weeks 
      end
      
      # getting the amount to be deducted, standard schema 
      
      @group_loan.reload
      
      deduction_hash = {} 
      initial_compulsory_savings_before_default_payment_hash = {}
      @group_loan.active_group_loan_memberships.each do |glm|
        if glm.default_payment.is_defaultee == false 
          deduction_hash[glm.id] = glm.default_payment.amount_of_compulsory_savings_deduction
          initial_compulsory_savings_before_default_payment_hash[glm.id] = glm.member.saving_book.total_compulsory_savings
        end
      end
      
      
      # testing copy paste code 
      @group_loan.reload
      @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
      @group_loan.is_default_payment_resolution_proposed.should be_true 
      @group_loan.reload
      @group_loan.execute_default_payment_execution( @cashier ) 
      @group_loan.is_default_payment_resolution_approved.should be_true 
      
      
      puts "\n\n********** deduction analytics"*5
      deduction_hash.each do |key,value|
        
        puts "The glm id : #{key}"
        glm = GroupLoanMembership.find_by_id key 
      
        initial_compulsory_savings = initial_compulsory_savings_before_default_payment_hash[key]
        puts "111 initial_compulsory savings: #{initial_compulsory_savings}"
        final_compulsory_savings = glm.member.saving_book.total_compulsory_savings
        puts "111 final compulsory_savings: #{final_compulsory_savings}"
        puts "glm.default_payment.amount_of_compulsory_savings_deduction : #{glm.default_payment.amount_of_compulsory_savings_deduction.to_s}"
        compulsory_savings_diff = initial_compulsory_savings - final_compulsory_savings
        puts "111 expected- diff : #{compulsory_savings_diff}"
      
        compulsory_savings_diff.should == deduction_hash[key]
        
      end
      
      
      extra_savings_before_group_loan_closing = []
      compulsory_savings_before_group_loan_closing = []
      
      @group_loan.reload
      
      initial_extra_savings_hash_pre_closing = {}
      initial_compulsory_savings_hash_pre_closing = {}
      @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
        initial_extra_savings_hash_pre_closing[glm.id] = glm.member.saving_book.total_extra_savings 
        initial_compulsory_savings_hash_pre_closing[glm.id] = glm.member.saving_book.total_compulsory_savings
      end
      
    
      
      @group_loan.close_group_loan(@branch_manager)
      @group_loan.is_closed.should be_true 
      
      #check -> extra savings diff should be the amount of final_compulsory savings 
      
      
      @group_loan.reload
      
      
      @group_loan.active_group_loan_memberships.each  do |glm|
        extra_savings_after_closing = glm.member.saving_book.total_extra_savings 

        diff = extra_savings_after_closing - initial_extra_savings_hash_pre_closing[glm.id]

        puts "expected diff in extra savings: #{diff}"
        diff.should == initial_compulsory_savings_hash_pre_closing[glm.id]
      end
    end
    

    # it "should do the final case #2b: unpaid backlogs at the end of grace period. " + 
    #     "distribute the pain to all non defaultee members." + 
    #     "and, for the defaultee, eat up the voluntary savings" do
    #   # strategy: take 50% out from each subgroup. paying only once. The rest is shared among other members. hehe.. looks good
    #   
    #   
    #   
    #   defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
    #   defaultee_glm_id_list = defaultee_glm_list.collect {|x| x.id }
    #   puts "the list: #{defaultee_glm_id_list}"
    #   
    #   # now we have 4.. each of them only pay once for weekly payment
    #   
    #   
    #   @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
    #     puts "======================\n"*2
    #     puts "\n\nin week: #{weekly_task.week_number}"
    #     @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
    #       # setup 
    #       
    #       # present in the weekly meeting. declaring no payment 
    #       if defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
    #         weekly_task.mark_attendance_as_present( glm.member, @field_worker )
    #         weekly_task.create_weekly_payment_declared_as_no_payment( glm.member )
    #         next
    #       end
    #       
    #       
    #       member =  glm.member 
    #       saving_book = member.saving_book
    #       initial_total_savings                = saving_book.total 
    #       initial_extra_savings                = saving_book.total_extra_savings
    #       initial_compulsory_savings           = saving_book.total_compulsory_savings
    # 
    #       glp = glm.group_loan_product
    #       
    #       
    #       
    #       #  mark member attendance  # the order doesn't matter 
    #       weekly_task.mark_attendance_as_present( glm.member, @field_worker )
    #       # do payment 
    #       weekly_task = @group_loan.currently_executed_weekly_task
    #       
    #       puts "\n++++++++++ pre condition"
    #       puts "member_id : #{member.id}"
    #       
    #       puts "initial compulsory_savings: #{initial_compulsory_savings}"
    #       puts "the currently_executed_weekly_task : #{weekly_task.week_number}"
    #       # TransactionActivity.create_basic_weekly_payment(member,weekly_task, @field_worker )
    #       cash_payment = glp.total_weekly_payment
    #       savings_withdrawal = BigDecimal("0")
    #       number_of_weeks = 1 
    #       number_of_backlogs = 0 
    #       a = TransactionActivity.create_generic_weekly_payment(
    #         weekly_task, 
    #               glm,
    #               @field_worker,
    #               cash_payment,
    #               savings_withdrawal, 
    #               number_of_weeks,
    #               number_of_backlogs
    #       )
    #       
    #       a.should be_valid 
    #       
    #   
    #       
    #       
    #       saving_book.reload
    #       
    #       final_total_savings      = saving_book.total 
    #       final_extra_savings      = saving_book.total_extra_savings
    #       final_compulsory_savings = saving_book.total_compulsory_savings
    #       diff = final_total_savings - initial_total_savings
    #       diff_extra_savings = final_extra_savings - initial_extra_savings
    #       diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
    #       
    #       
    #       puts "final compulsory_savings: #{final_compulsory_savings}"
    #       puts "\n******THE ANALYTICS"
    #       puts "glp min_savings : #{glp.min_savings}"
    #       puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
    #       puts "diff extra_savings: #{diff_extra_savings.to_i}"
    #       puts "The amount of diff for member #{member.id}: #{diff}"
    #       
    #       a.should be_valid 
    #   
    #       
    #       puts "~~~~~ the assertion"
    #       diff.should == glp.min_savings
    #       diff_compulsory_savings.to_i.should == glp.min_savings.to_i
    #       diff_extra_savings.should == BigDecimal("0")
    #       
    #       
    #       
    #     end
    #     weekly_task.close_weekly_meeting(@field_worker)
    #     weekly_task.close_weekly_payment( @field_worker )
    #     weekly_task.approve_weekly_payment_collection( @cashier )
    #     
    #     weekly_task.is_weekly_attendance_marking_done.should be_true 
    #     weekly_task.is_weekly_payment_collection_finalized.should be_true 
    #     weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
    #   end
    #   
    #   
    #   # THE BEGINNING OF GRACCE PERIOD 
    #   defaultee_glm_list.each do |glm|
    #     glm.reload
    #     glm.unpaid_backlogs.count.should == @group_loan.total_weeks 
    #   end
    #   
    #   # getting the amount to be deducted, standard schema 
    #   
    #   @group_loan.reload
    #   
    #   deduction_hash = {} 
    #   initial_compulsory_savings_before_default_payment_hash = {}
    #   @group_loan.active_group_loan_memberships.each do |glm|
    #     if glm.default_payment.is_defaultee == false 
    #       deduction_hash[glm.id] = glm.default_payment.amount_to_be_paid
    #       initial_compulsory_savings_before_default_payment_hash[glm.id] = glm.member.saving_book.total_compulsory_savings
    #     end
    #   end
    #   
    #   
    #   # testing copy paste code 
    #   @group_loan.reload
    #   @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
    #   @group_loan.reload
    #   @group_loan.execute_default_payment_execution( @cashier ) 
    #   
    #   
    #   puts "\n\n********** deduction analytics"*5
    #   deduction_hash.each do |key,value|
    #     
    #     puts "The glm id : #{key}"
    #     glm = GroupLoanMembership.find_by_id key 
    #   
    #     initial_compulsory_savings = initial_compulsory_savings_before_default_payment_hash[key]
    #     puts "initial_compulsory savings: #{initial_compulsory_savings}"
    #     final_compulsory_savings = glm.member.saving_book.total_compulsory_savings
    #     puts "final compulsory_savings: #{final_compulsory_savings}"
    #     compulsory_savings_diff = initial_compulsory_savings - final_compulsory_savings
    #     puts "expected- diff : #{compulsory_savings_diff}"
    #     compulsory_savings_diff.should == deduction_hash[key]
    #     
    #   end
    #   
    #   
    #   extra_savings_before_group_loan_closing = []
    #   compulsory_savings_before_group_loan_closing = []
    #   
    #   @group_loan.reload
    #   
    #   initial_extra_savings_hash_pre_closing = {}
    #   initial_compulsory_savings_hash_pre_closing = {}
    #   @group_loan.active_group_loan_memberships.order("created_at ASC").each do |glm|
    #     initial_extra_savings_hash_pre_closing[glm.id] = glm.member.saving_book.total_extra_savings 
    #     initial_compulsory_savings_hash_pre_closing[glm.id] = glm.member.saving_book.total_compulsory_savings
    #   end
    #   
    # 
    #   
    #   @group_loan.close_group_loan(@branch_manager)
    #   @group_loan.is_closed.should be_true 
    #   
    #   #check -> extra savings diff should be the amount of final_compulsory savings 
    #   
    #   
    #   @group_loan.reload
    #   
    #   
    #   @group_loan.active_group_loan_memberships.each  do |glm|
    #     extra_savings_after_closing = glm.member.saving_book.total_extra_savings 
    # 
    #     diff = extra_savings_after_closing - initial_extra_savings_hash_pre_closing[glm.id]
    # 
    #     puts "expected diff in extra savings: #{diff}"
    #     diff.should == initial_compulsory_savings_hash_pre_closing[glm.id]
    #   end
    #   
    #   
    #    
    # end
    
    
    it 'should do the case #2c: unpaid backlogs at the end' + 
      'pay the grace payment that will result in default payment update  ' + 
      'update the distribution of defaults to non defaultee'  do
    end
      
      
    
    
    it "should do the final case #3: unpaid backlogs at the end of grace period. distribute the pain to all non defaultee members. CUSTOM-schema" do
      puts " SHIT SHIT "
    end
    
    
   
  end
end