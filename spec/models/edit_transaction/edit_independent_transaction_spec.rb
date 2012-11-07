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
    #          :commune_id => @group_loan_commune }, @branch_manager)
    
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
      @weekly_task.close_weekly_meeting(@field_worker)
      @weekly_task.close_weekly_payment( @field_worker )
      @weekly_task.approve_weekly_payment_collection( @cashier )
      
      @weekly_task.is_weekly_attendance_marking_done.should be_true 
      @weekly_task.is_weekly_payment_collection_finalized.should be_true 
      @weekly_task.is_weekly_payment_approved_by_cashier.should be_true
      
      
    end
    
    context 'testing from only savings independent payment' do
      before(:each) do
        @independent_cash = BigDecimal("5000")
        @first_member = @first_glm.member 
        @initial_voluntary_savings = @first_member.saving_book.total_extra_savings
        @initial_compulsory_savings = @first_member.saving_book.total_compulsory_savings 
        ActiveRecord::Base.transaction do
          @only_savings_independent_payment  = TransactionActivity.create_only_extra_savings_independent_payment( 
            @first_glm, 
            @field_worker, 
            @independent_cash, false   )
        end
        @number_of_weeks = 1 
        @number_of_backlogs = 0 
        
        puts "``333 the innitial voluntary savings: #{@initial_voluntary_savings}"
        
        @first_glm.reload
        @voluntary_savings_after_first_transaction = @first_glm.member.saving_book.total_extra_savings
        @first_glm.member.saving_book.total_extra_savings.should == @independent_cash
        puts "voluntary savings after the first transaction: #{@first_glm.member.saving_book.total_extra_savings.to_i}"
      end
      
      
      it 'should create extra savings' do
        @first_member.reload 
        @final_voluntary_savings = @first_member.saving_book.total_extra_savings 
        
        voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
        puts "``333 the  voluntary savings after first transaction: #{@independent_cash}"
        voluntary_savings_diff.should == @independent_cash 
        @first_glm.unapproved_independent_payment.should be_valid 
        
        @first_glm.unapproved_independent_payment.id.should == @only_savings_independent_payment.id  
        
        MemberPaymentHistory.where(
          :member_id                  => @first_member.id ,
          :loan_product_id            => @group_loan.id , 
          :cash                       => @independent_cash,   
          :transaction_activity_id    => @only_savings_independent_payment.id ,
          :revision_code              => REVISION_CODE[:original_independent_only_savings],
          :payment_phase              => PAYMENT_PHASE[:independent_payment]
        ).count == 1
        
      
        @only_savings_independent_payment.transaction_entries.count.should == 1 
        @only_savings_independent_payment.transaction_entries.
            where(:transaction_entry_code => TRANSACTION_ENTRY_CODE[:only_savings_independent_payment]).count.should == 1 
        
       
      end
      
      it 'should not create any more independent payment' do 
        @only_savings_independent_payment_second  = TransactionActivity.create_only_extra_savings_independent_payment( 
          @first_glm, 
          @field_worker, 
          @independent_cash, false   )
        @only_savings_independent_payment_second.should be_nil 
      end
      
      it 'should be able to update to only savings' do
        @first_glm.reload 
        # @independent_cash = BigDecimal("5000")
        @new_independent_cash =  BigDecimal('8000')
        @revision_independent_payment  = TransactionActivity.update_only_extra_savings_independent_payment( 
          @first_glm, 
          @field_worker, 
          @new_independent_cash  )
          
         
        @final_voluntary_savings = @first_glm.member.saving_book.total_extra_savings 

        # initial voluntary savings == 0.. before the first transcaction 
        # after the first transaction, it is # @independent_cash = BigDecimal("5000")
        voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
        
        puts "888 actual voluntary savings diff: #{voluntary_savings_diff.to_i}"
        puts "888 expected voluntary savings diff: #{@new_independent_cash.to_i}"
        puts "888  @initial_voluntary_savings : #{ @initial_voluntary_savings .to_i}"
        puts "888 @final_voluntary_savings: #{@final_voluntary_savings.to_i}"
        voluntary_savings_diff.should == @new_independent_cash 
        @first_glm.unapproved_independent_payment.should be_valid 

        @first_glm.unapproved_independent_payment.id.should == @revision_independent_payment.id
        
      end
      
      # it 'should be able to update to generic independent' do
      #   @new_extra_savings = BigDecimal('4000')
      #   @new_cash =  @first_glm.group_loan_product.total_weekly_payment  + @new_extra_savings
      #   @revision_independent_generic_payment  = TransactionActivity.update_generic_independent_payment( 
      #     @first_glm,
      #     @field_worker,
      #     @new_cash, 
      #     @savings_withdrawal,
      #     @number_of_weeks,
      #     @number_of_backlogs )
      #     
      #   @first_member.reload 
      #   @final_voluntary_savings = @first_member.saving_book.total_extra_savings 
      # 
      #   voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
      # 
      #   puts "initial cash payment: #{@initial_cash.to_i}"
      #   puts "update cash payment: #{@new_cash.to_i}"
      #   puts "basic weekly payment: #{@first_glm.group_loan_product.total_weekly_payment.to_i}"
      #   puts "xx333 initial voluntary savings : #{@initial_voluntary_savings.to_i}"
      #   puts "xx333 actual voluntary savings diff: #{voluntary_savings_diff.to_i}"
      #   puts "xx333 expected voluntary savings diff: #{@new_extra_savings.to_i}"
      #   voluntary_savings_diff.should == @new_extra_savings 
      #   
      #   @revision_independent_generic_payment.should be_valid 
      #   @first_glm.reload 
      #   @first_glm.unapproved_independent_payment.should be_valid 
      #   @first_glm.unapproved_independent_payment.id.should == @revision_independent_generic_payment.id 
      #   puts "--------------\n\n\n"
      # end
      
    end # end of context only savings independent payment 
    
    # context 'do generic independent payment savings' do
    #   before(:each) do
    #     @independent_cash = BigDecimal("5000")
    #     @first_member = @first_glm.member 
    #     @initial_voluntary_savings = @first_member.saving_book.total_extra_savings
    #     @initial_compulsory_savings = @first_member.saving_book.total_compulsory_savings 
    #     @cash = @first_glm.group_loan_product.total_weekly_payment 
    #     @savings_withdrawal = BigDecimal('0')
    #     @number_of_weeks  = 1 
    #     @number_of_backlogs = 0 
    #     @extra_savings = BigDecimal('40000')
    #     @initial_cash = @cash + @extra_savings
    #     ActiveRecord::Base.transaction do
    #       @generic_independent_payment  = TransactionActivity.create_generic_independent_payment(
    #               @first_glm,
    #               @field_worker,
    #               @initial_cash, 
    #               @savings_withdrawal,
    #               @number_of_weeks,
    #               @number_of_backlogs,
    #               false)
    #     end
    #   end
    #   
    #   it 'should create generic independent payment' do 
    #     @first_member.reload 
    #     @final_voluntary_savings = @first_member.saving_book.total_extra_savings 
    #     
    #     voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
    #     voluntary_savings_diff.should == @extra_savings 
    #     
    #     @first_glm.unapproved_independent_payment.should be_valid 
    #     
    #     @first_glm.unapproved_independent_payment.id.should == @generic_independent_payment.id  
    #     
    #     MemberPaymentHistory.where(
    #       :member_id                  => @first_member.id ,
    #       :loan_product_id            => @group_loan.id , 
    #       :cash                       =>  @cash + @extra_savings,   
    #       :transaction_activity_id    => @generic_independent_payment.id ,
    #       :revision_code              => REVISION_CODE[:original_independent_normal],
    #       :payment_phase              => PAYMENT_PHASE[:independent_payment]
    #     ).count == 1
    #   end
    #   
    #   it 'should not allow more than 1 outstanding independent payment' do
    #     ActiveRecord::Base.transaction do
    #       @new  = TransactionActivity.create_generic_independent_payment(
    #               @first_glm,
    #               @field_worker,
    #               @cash + @extra_savings, 
    #               @savings_withdrawal,
    #               @number_of_weeks,
    #               @number_of_backlogs,
    #               false)
    #     end
    #     @new.should be_nil 
    #   end
    #   
    #   it 'should be able to update to generic independent' do
    #     @new_extra_savings = BigDecimal('4000')
    #     @new_cash =  @first_glm.group_loan_product.total_weekly_payment  + @new_extra_savings
    #     @revision_independent_generic_payment  = TransactionActivity.update_generic_independent_payment( 
    #       @first_glm,
    #       @field_worker,
    #       @new_cash, 
    #       @savings_withdrawal,
    #       @number_of_weeks,
    #       @number_of_backlogs )
    #       
    #     @first_member.reload 
    #     @final_voluntary_savings = @first_member.saving_book.total_extra_savings 
    # 
    #     voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
    #   
    #     puts "initial cash payment: #{@initial_cash.to_i}"
    #     puts "update cash payment: #{@new_cash.to_i}"
    #     puts "basic weekly payment: #{@first_glm.group_loan_product.total_weekly_payment.to_i}"
    #     puts "xx333 initial voluntary savings : #{@initial_voluntary_savings.to_i}"
    #     puts "xx333 actual voluntary savings diff: #{voluntary_savings_diff.to_i}"
    #     puts "xx333 expected voluntary savings diff: #{@new_extra_savings.to_i}"
    #     voluntary_savings_diff.should == @new_extra_savings 
    #     
    #     @revision_independent_generic_payment.should be_valid 
    #     @first_glm.reload 
    #     @first_glm.unapproved_independent_payment.should be_valid 
    #     @first_glm.unapproved_independent_payment.id.should == @revision_independent_generic_payment.id 
    #     puts "--------------\n\n\n"
    #   end
    #   
    #   it 'should be able to update to only savings independent payment' do
    #     @new_extra_savings = BigDecimal('1000')
    #     @new_cash =  @cash + @new_extra_savings
    #     @revision_independent_generic_payment  = TransactionActivity.update_only_extra_savings_independent_payment( 
    #         @first_glm, 
    #         @field_worker, 
    #         @new_cash  )
    #       
    #     
    #     
    #     @final_voluntary_savings = @first_member.saving_book.total_extra_savings 
    #     @final_compulsory_savings = @first_member.saving_book.total_compulsory_savings 
    # 
    #     voluntary_savings_diff = @final_voluntary_savings - @initial_voluntary_savings 
    #     compulsory_savings_diff = @final_compulsory_savings - @initial_compulsory_savings 
    #   
    #     puts "888 actual voluntary savings diff: #{voluntary_savings_diff.to_i}"
    #     puts "888 expected voluntary savings diff: #{@new_independent_cash.to_i}"
    #     voluntary_savings_diff.should == @new_cash 
    #     compulsory_savings_diff.should == BigDecimal('0')
    #     
    #     @revision_independent_generic_payment.should be_valid 
    #     @first_glm.reload 
    #     @first_glm.unapproved_independent_payment.should be_valid 
    #     @first_glm.unapproved_independent_payment.id.should == @revision_independent_generic_payment.id 
    #     
    #     @first_glm.unapproved_independent_payment.number_of_weeks_paid.should == 0 
    #   end
    #   
    #   
    #   
    # end
   
  end  # end of context 'do payment on week 1'
  
  
end