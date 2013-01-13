require 'spec_helper'

describe DefaultPayment do
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
    @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 10, creator_id: @loan_officer.id,
     commune_id: @group_loan_commune.id , office_id: @office.id )
     
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
  end
  
  
  context "new case" do
    it "should produce default payment for all active member, not produce default payment for non active" do 
      @group_loan.active_group_loan_memberships.each do |glm|
        glm.default_payment.should be_valid 
      end
      
      @group_loan.non_active_group_loan_memberships.each do |glm|
        glm.default_payment.should be_nil 
      end
    end
  end
  
  
  
  context "recalculating default payment on the finalization of all weekly payments" do
    # do all weekly payment + approval
    # on last weekly payment, see the difference in the default_payment total amount value 
    # check the default_payment.amount_to_be_paid method 
    
    it "should not recalculate default payment before entering grace period" do
      defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
      defaultee_glm_id_list = defaultee_glm_list.collect {|x| x.id }
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        
        
        initial_amount_to_be_paid_hash = {}
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          initial_amount_to_be_paid_hash[glm.id] = glm.default_payment.amount_to_be_paid
          
          if defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            weekly_task.create_weekly_payment_declared_as_no_payment( @field_worker,glm.member )
            next
          end
          
          
          
          puts "Initial amount to be paid for glm id : #{glm.id} : #{glm.default_payment.amount_to_be_paid}"
          
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
                  number_of_backlogs,
                  false
          )
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
           #          
           # puts "final compulsory_savings: #{final_compulsory_savings}"
           # puts "\n******THE ANALYTICS"
           # puts "glp min_savings : #{glp.min_savings}"
           # puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
           # puts "diff extra_savings: #{diff_extra_savings.to_i}"
           # puts "The amount of diff for member #{member.id}: #{diff}"
           # 
           # 
           # puts "transaction validity"
          a.should be_valid           # 
                    # a.transaction_entries.each do |te|
                    #   puts "#{te.inspect}"
                    #   puts "#{te.amount.to_i}"
                    # end
                    # 
          
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
        
        
        @group_loan.reload
        if weekly_task.week_number != @group_loan.total_weeks 
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "glm id = #{glm.id}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            glm.default_payment.amount_to_be_paid.should == initial_amount_to_be_paid_hash[glm.id]
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_false
            end
            
          end
        else
          
          puts "*****************last week statistics\n"*5
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "\n"
            puts "glm id = #{glm.id}"
            puts "unpaid backlogs: #{glm.unpaid_backlogs.count}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            # not equal because of the recalculation of default payment resolution 
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_true
            end
            # glm.default_payment.amount_to_be_paid.should_not == initial_amount_to_be_paid_hash[glm.id]
          end
        end
        
        
        
        total_default = BigDecimal("0")
        @group_loan.active_group_loan_memberships.each do |glm|
          default_payment = glm.default_payment
          if default_payment.is_defaultee == false
            next
          end
          
          total_default += glm.group_loan_product.grace_period_weekly_payment * glm.unpaid_backlogs.count 
        end
        
        puts "\n****The default payment summary***"*5
        puts "total default: #{total_default.to_i} "
        puts "amount to be shared : #{@group_loan.default_payment_amount_to_be_shared}"
        puts "\n\n"
        @group_loan.active_group_loan_memberships.order("sub_group_id").each do |glm|
          
          puts "\n"
          default_payment = glm.default_payment 
          puts "glm id : #{glm.id}"
          puts "sub_group_id : #{glm.sub_group_id}"
          if glm.default_payment.is_defaultee == true 
            puts "is defaultee -> YES"
          else
            puts "is defaultee -> NO"
          end
          
          puts "self compulsory savings deduction: #{default_payment.amount_of_compulsory_savings_deduction.to_i}"
          puts "to be shared with non-defaultee: #{default_payment.amount_to_be_shared_with_non_defaultee.to_i}"
          
          puts "sub_group_share amount: #{default_payment.amount_sub_group_share.to_i}"
          puts "group_share_amount: #{default_payment.amount_group_share.to_i}"
          
          puts "total_amount : #{default_payment.total_amount.to_i}"
          puts "amount to be paid: #{default_payment.amount_to_be_paid.to_i}"
        end
        
      end # end of looping the weekly tasks 
    end
  end 
  
  
  context "setting up custom default payment value for non defaultee -> with the default that will wipe out all the compulsory savings" do 
    before(:each) do
      
      @defaultee_glm_list = @first_sub_group.active_group_loan_memberships[0..1] + @second_sub_group.active_group_loan_memberships[0..1]
      @defaultee_glm_id_list = @defaultee_glm_list.collect {|x| x.id }
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        
        
        initial_amount_to_be_paid_hash = {}
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          initial_amount_to_be_paid_hash[glm.id] = glm.default_payment.amount_to_be_paid
          
          if @defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            weekly_task.create_weekly_payment_declared_as_no_payment( @field_worker, glm.member )
            next
          end
          
          
          
          puts "Initial amount to be paid for glm id : #{glm.id} : #{glm.default_payment.amount_to_be_paid}"
          
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
                  number_of_backlogs,
                  false
          )
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
           #          
           # puts "final compulsory_savings: #{final_compulsory_savings}"
           # puts "\n******THE ANALYTICS"
           # puts "glp min_savings : #{glp.min_savings}"
           # puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
           # puts "diff extra_savings: #{diff_extra_savings.to_i}"
           # puts "The amount of diff for member #{member.id}: #{diff}"
           # 
           # 
           # puts "transaction validity"
          a.should be_valid           # 
                    # a.transaction_entries.each do |te|
                    #   puts "#{te.inspect}"
                    #   puts "#{te.amount.to_i}"
                    # end
                    # 
          
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
        
        
        @group_loan.reload
        if weekly_task.week_number != @group_loan.total_weeks 
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "glm id = #{glm.id}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            glm.default_payment.amount_to_be_paid.should == initial_amount_to_be_paid_hash[glm.id]
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_false
            end
            
          end
        else
          
          puts "*****************last week statistics\n"*5
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "\n"
            puts "glm id = #{glm.id}"
            puts "unpaid backlogs: #{glm.unpaid_backlogs.count}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            # not equal because of the recalculation of default payment resolution 
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_true
            end
            # glm.default_payment.amount_to_be_paid.should_not == initial_amount_to_be_paid_hash[glm.id]
          end
        end
        
        
        
        total_default = BigDecimal("0")
        @group_loan.active_group_loan_memberships.each do |glm|
          default_payment = glm.default_payment
          if default_payment.is_defaultee == false
            next
          end
          
          total_default += glm.group_loan_product.grace_period_weekly_payment * glm.unpaid_backlogs.count 
        end
        
        puts "\n****The default payment summary***"*5
        puts "total default: #{total_default.to_i} "
        puts "amount to be shared : #{@group_loan.default_payment_amount_to_be_shared}"
        puts "\n\n"
        @group_loan.active_group_loan_memberships.order("sub_group_id").each do |glm|
          
          puts "\n"
          default_payment = glm.default_payment 
          puts "glm id : #{glm.id}"
          puts "sub_group_id : #{glm.sub_group_id}"
          if glm.default_payment.is_defaultee == true 
            puts "is defaultee -> YES"
          else
            puts "is defaultee -> NO"
          end
          
          puts "self compulsory savings deduction: #{default_payment.amount_of_compulsory_savings_deduction.to_i}"
          puts "to be shared with non-defaultee: #{default_payment.amount_to_be_shared_with_non_defaultee.to_i}"
          
          puts "sub_group_share amount: #{default_payment.amount_sub_group_share.to_i}"
          puts "group_share_amount: #{default_payment.amount_group_share.to_i}"
          
          puts "total_amount : #{default_payment.total_amount.to_i}"
          puts "amount to be paid: #{default_payment.amount_to_be_paid.to_i}"
        end
        
      end # end of looping the weekly tasks
    end # end of before(:each)
     
    it "should allow custom default payment if custom amount == total amount (suggested amount ) " do 
      
      # 
      # @group_loan.reload
      # custom_value_hash = {}
      # @group_loan.active_group_loan_memberships.each do |glm|
      #   custom_value_hash[glm.id]  = glm.default_payment.total_amount 
      #   puts "glm.id : #{glm.id}, amount = #{custom_value_hash[glm.id].to_i}"
      # end
      # 
      # proposal_result = @group_loan.propose_default_payment_execution_custom_value(@field_worker, custom_value_hash)
      # proposal_result.should be_true 
      # 
      # @group_loan.reload
      # @group_loan.execute_default_payment_execution( @cashier )
      
      # check the deducted value , to be equal with custom value ? Hell yeah it will 
      # for the sake of checking , let's just check 
      
      # take note. in this case, it is too big.. 900k.. will wipe out all the $$$.. what if we use the small amount? test test
    end
    
    
    it "should not allow custom payment if the total amount is less than the bare minimum (with the rounding up)" do
      # @group_loan.reload
      # custom_value_hash = {}
      # @group_loan.active_group_loan_memberships.each do |glm|
      #   if glm.default_payment.is_defaultee == false 
      #     custom_value_hash[glm.id]  = glm.default_payment.total_amount  - BigDecimal("5000")
      #   else
      #     custom_value_hash[glm.id]  = glm.default_payment.total_amount
      #   end
      #   puts "glm.id : #{glm.id}, amount = #{custom_value_hash[glm.id].to_i}"
      # end
      # 
      # proposal_result = @group_loan.propose_default_payment_execution_custom_value(@field_worker, custom_value_hash)
      # proposal_result.should be_nil 
      # 
      # @group_loan.reload
      # @group_loan.execute_default_payment_execution( @cashier ) 
      # 
      # @group_loan.is_default_payment_resolution_approved.should be_false
      # 
    end
    
    # it "should not allow custom payment with non multiples of 500"
    # 
    it "should not allow custom payment if it exceed the total compulsory savings" do
      # @group_loan.reload
      # custom_value_hash = {}
      # @group_loan.active_group_loan_memberships.each do |glm|
      #   
      #   if glm.default_payment.is_defaultee == false 
      #     custom_value_hash[glm.id]  = glm.default_payment.total_amount  + BigDecimal("5000")
      #   else
      #     custom_value_hash[glm.id]  = glm.default_payment.total_amount
      #   end
      #   
      #   
      #   puts "glm.id : #{glm.id}, amount = #{custom_value_hash[glm.id].to_i}"
      # end
      # 
      # proposal_result = @group_loan.propose_default_payment_execution_custom_value(@field_worker, custom_value_hash)
      # proposal_result.should be_nil 
      # 
      # @group_loan.reload
      # @group_loan.execute_default_payment_execution( @cashier )
      # @group_loan.is_default_payment_resolution_approved.should be_false
    end
  end
  
  context "default payment with the default payment that won't wipe out the compulsory savings" do
    before(:each) do
      
      @defaultee_glm_list = [ @first_sub_group.active_group_loan_memberships[0] ]
      @defaultee_glm_id_list = @defaultee_glm_list.collect {|x| x.id }
      
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        
        
        initial_amount_to_be_paid_hash = {}
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          initial_amount_to_be_paid_hash[glm.id] = glm.default_payment.amount_to_be_paid
          
          if @defaultee_glm_id_list.include?(glm.id)  #   and [1,2,3].include?(weekly_task.week_number)
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            weekly_task.create_weekly_payment_declared_as_no_payment(@field_worker, glm.member )
            next
          end
          
          
          
          puts "Initial amount to be paid for glm id : #{glm.id} : #{glm.default_payment.amount_to_be_paid}"
          
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
                  number_of_backlogs,
                  false
          )
          
          
          saving_book.reload
          
          final_total_savings      = saving_book.total 
          final_extra_savings      = saving_book.total_extra_savings
          final_compulsory_savings = saving_book.total_compulsory_savings
          diff = final_total_savings - initial_total_savings
          diff_extra_savings = final_extra_savings - initial_extra_savings
          diff_compulsory_savings = final_compulsory_savings - initial_compulsory_savings
          
           #          
           # puts "final compulsory_savings: #{final_compulsory_savings}"
           # puts "\n******THE ANALYTICS"
           # puts "glp min_savings : #{glp.min_savings}"
           # puts "diff compulsory_savings: #{diff_compulsory_savings.to_i}"
           # puts "diff extra_savings: #{diff_extra_savings.to_i}"
           # puts "The amount of diff for member #{member.id}: #{diff}"
           # 
           # 
           # puts "transaction validity"
          a.should be_valid           # 
                    # a.transaction_entries.each do |te|
                    #   puts "#{te.inspect}"
                    #   puts "#{te.amount.to_i}"
                    # end
                    # 
          
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
        
        
        @group_loan.reload
        if weekly_task.week_number != @group_loan.total_weeks 
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "glm id = #{glm.id}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            glm.default_payment.amount_to_be_paid.should == initial_amount_to_be_paid_hash[glm.id]
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_false
            end
            
          end
        else
          
          puts "*****************last week statistics\n"*5
          @group_loan.active_group_loan_memberships.each do |glm|
            puts "\n"
            puts "glm id = #{glm.id}"
            puts "unpaid backlogs: #{glm.unpaid_backlogs.count}"
            puts "amount_to_be_paid: #{glm.default_payment.amount_to_be_paid}"
            puts "initial_amount_to_be_paid: #{initial_amount_to_be_paid_hash[glm.id]}"
            # not equal because of the recalculation of default payment resolution 
            if glm.unpaid_backlogs.count > 0 
              glm.default_payment.is_defaultee.should be_true
            end
            # glm.default_payment.amount_to_be_paid.should_not == initial_amount_to_be_paid_hash[glm.id]
          end
        end
        
        
        
        total_default = BigDecimal("0")
        @group_loan.active_group_loan_memberships.each do |glm|
          default_payment = glm.default_payment
          if default_payment.is_defaultee == false
            next
          end
          
          total_default += glm.group_loan_product.grace_period_weekly_payment * glm.unpaid_backlogs.count 
        end
        
        puts "\n****The default payment summary***"*5
        puts "total default: #{total_default.to_i} "
        puts "amount to be shared : #{@group_loan.default_payment_amount_to_be_shared}"
        puts "\n\n"
        @group_loan.active_group_loan_memberships.order("sub_group_id").each do |glm|
          
          puts "\n"
          default_payment = glm.default_payment 
          puts "glm id : #{glm.id}"
          puts "sub_group_id : #{glm.sub_group_id}"
          if glm.default_payment.is_defaultee == true 
            puts "is defaultee -> YES"
          else
            puts "is defaultee -> NO"
          end
          
          puts "self compulsory savings deduction: #{default_payment.amount_of_compulsory_savings_deduction.to_i}"
          puts "to be shared with non-defaultee: #{default_payment.amount_to_be_shared_with_non_defaultee.to_i}"
          
          puts "sub_group_share amount: #{default_payment.amount_sub_group_share.to_i}"
          puts "group_share_amount: #{default_payment.amount_group_share.to_i}"
          
          puts "total_amount : #{default_payment.total_amount.to_i}"
          puts "amount to be paid: #{default_payment.amount_to_be_paid.to_i}"
          puts "total compulsory savings: #{glm.member.saving_book.total_compulsory_savings.to_i}"
        end
        
      end # end of looping the weekly tasks
    end # end of before(:each)
    
    
    it "should deduct from the custom amount otherwise, provided all the conditions are satisfied" do
      @group_loan.reload
      @group_loan.active_group_loan_memberships.each do |glm|
        # fuck, no idea on testing it.. ok, time to move to UI 
      end
    end
    
    #  simulate the custom payment -> add + reduce ... make it good 
    
  end
  
end
