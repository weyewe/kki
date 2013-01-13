require 'spec_helper'

describe TransactionActivity do
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
 
    # => propose loan disbursement attendance finalization
    @group_loan.propose_loan_disbursement_attendance_finalization(@field_worker)
    
    # do the actual disbursement 
    @group_loan.reload 
    # do the actual transaction 
    @group_loan.group_loan_memberships.each do |glm|
      glm.deduct_setup_payment_from_loan = true
      glm.save 
      TransactionActivity.execute_loan_disbursement( glm , @field_worker )
    end
    
    @group_loan.finalize_loan_disbursement_attendance_summary(@branch_manager )
    @group_loan.execute_finalize_loan_disbursement(@cashier)
    
    # post conditions => 3 members are out 
  end # end of before(:each block)
  
  context 'paying weekly payment, not in the weekly meeting' do
    it 'should bound the independent payment to the next weekly task' do
      # do the payment for the first week, propose finalization 
        @first_glm = @group_loan.active_group_loan_memberships.first 
        weekly_task =  @group_loan.currently_executed_weekly_task
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          if glm.id == @first_glm.id 
            puts "66666666666 the declaration as no payment"
            weekly_task.create_weekly_payment_declared_as_no_payment( @field_worker, glm.member )
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
        # weekly_task.approve_weekly_payment_collection( @cashier )
 
      
      
      
  
      puts "NUmber of backlogs: #{BacklogPayment.count}"
      puts "number of glm unpaid: #{@first_glm.unpaid_backlogs.count}"
      # then, create independent payment: backlogs payment 
      independent_transaction = TransactionActivity.create_generic_independent_payment(
              @first_glm,
              @field_worker,
              @first_glm.group_loan_product.total_weekly_payment, 
              BigDecimal("0"),
              0,
              1,
              false)
              
      independent_transaction.should be_valid
      
      # first week finalization by cashier : no problem 
      weekly_task.approve_weekly_payment_collection( @cashier )
      
      puts "unapproved independent payment: #{weekly_task.group_independent_payment_transactions.where(:is_approved => false).count}"
      weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
      weekly_task.group_payment_transactions.each do |transaction_activity|
        transaction_activity.is_approved.should be_true 
        transaction_activity.approver_id.should == @cashier.id 
      end
      
      ############################## Start the 2nd weekly cycle, independent payment hasn't been approved
      weekly_task =  @group_loan.currently_executed_weekly_task
      weekly_task.week_number.should == 2 
      @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
        # setup 
        
        if glm.id == @first_glm.id 
          puts "66666666666 the declaration as no payment"
          weekly_task.create_weekly_payment_declared_as_no_payment(@field_worker,  glm.member )
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
      weekly_task.is_weekly_payment_approved_by_cashier.should be_false
      # do the next weekly meeting -> can't be approved before the independent payment has been approved 
      independent_transaction.approve_payment(@cashier)
      independent_transaction.is_approved.should be_true
      independent_transaction.approver_id.should == @cashier.id 
      
      weekly_task.approve_weekly_payment_collection( @cashier )
      weekly_task.is_weekly_payment_approved_by_cashier.should be_true
    end
    
    it 'should not allow the independent payment if the final weekly meeting has taken place' do
      @first_glm = @group_loan.active_group_loan_memberships.first 
      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 
          
          if glm.id == @first_glm.id 
            weekly_task.create_weekly_payment_declared_as_no_payment( @field_worker, glm.member )
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
        
        if weekly_task.week_number != @group_loan.weekly_tasks.count
          weekly_task.approve_weekly_payment_collection( @cashier )
          weekly_task.is_weekly_attendance_marking_done.should be_true 
          weekly_task.is_weekly_payment_collection_finalized.should be_true 
          weekly_task.is_weekly_payment_approved_by_cashier.should be_true
        end
      end
      
      # try to create independent payment 
      independent_transaction = TransactionActivity.create_generic_independent_payment(
              @first_glm,
              @field_worker,
              @first_glm.group_loan_product.total_weekly_payment, 
              BigDecimal("0"),
              0,
              1,
              false)
              
      independent_transaction.should be_nil
    end
    
    it 'should not allow weekly payment to be approved '+
          'if there is un approved independent payment bound to that week' do
            # done in the example #1 
    end
      
  end
  

  
end