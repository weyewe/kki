require 'spec_helper'

# simple case: 1 defaultee, 2 stories: 1: can pay within his own means, 2. must be distributed to friends 
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
    
    
    # CREATE NO PAYMENT / ONLY SAVINGS as weekly payment 
    @defaultee_glm_list = [ @group_loan.active_group_loan_memberships.first]
    @defaultee_glm_id_list = @defaultee_glm_list.collect {|x| x.id }
    puts "the list: #{@defaultee_glm_id_list}"

    # now we have 4.. each of them only pay once for weekly payment

    @group_loan.active_group_loan_memberships.each do |glm|
      TransactionActivity.create_independent_savings( glm.member,  BigDecimal("20000"), @field_worker )
    end

  end # end of before(:each block)
  
  context "case1: single defaultee, can absorb default alone through compulsory and voluntary savings" do
    before(:each) do


      @group_loan.weekly_tasks.order("week_number ASC").each do |weekly_task| 
        puts "======================\n"*2
        puts "\n\nin week: #{weekly_task.week_number}"
        @group_loan.active_group_loan_memberships.includes(:member).each do |glm|
          # setup 

          # present in the weekly meeting. declaring no payment 
          if @defaultee_glm_id_list.include?(glm.id)   
            weekly_task.mark_attendance_as_present( glm.member, @field_worker )
            TransactionActivity.create_savings_only_weekly_payment(
              glm.member,
              weekly_task,
              glm.group_loan_product.grace_period_weekly_payment,
              @field_worker
            )
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

          a.should be_valid 


        end
        weekly_task.close_weekly_meeting(@field_worker)
        weekly_task.close_weekly_payment( @field_worker )
        weekly_task.approve_weekly_payment_collection( @cashier )

        weekly_task.is_weekly_attendance_marking_done.should be_true 
        weekly_task.is_weekly_payment_collection_finalized.should be_true 
        weekly_task.is_weekly_payment_approved_by_cashier.should be_true 
      end
      
  
    end # end of before(:each)
    
    it 'should only have 1 defaultee in the active group loan memberships'  do
      @group_loan.active_group_loan_memberships.joins(:default_payment).where(:default_payment => {:is_defaultee => true}).count.should == 1
    end
    
    # it 'should produce defaultee with total savings > total amount to be paid' do
    #   defaultee_glm = @group_loan.active_group_loan_memberships.
    #                     joins(:default_payment).
    #                     where(:default_payment => {:is_defaultee => true}).first
    #   defaultee_member = defaultee_glm.member 
    #   total_savings = defaultee_member.saving_book.total 
    #   total_savings.should be >= defaultee_glm.default_payment.amount_to_be_paid 
    # end
    
    context "on default loan resolution execution" do
      before(:each) do
        @group_loan.reload
        @group_loan.propose_default_payment_execution( @field_worker ) # cashier is notified
        # @group_loan.is_default_payment_resolution_proposed.should be_true #because we need to approve all pending transactions in grace period
        #  @group_loan.reload
        #  @group_loan.execute_default_payment_execution( @cashier ) 
        #  @group_loan.is_default_payment_resolution_approved.should be_true
      end
      
      it 'should have proposed the default_payment resolution' do
        @group_loan.is_default_payment_resolution_proposed.should be_true
      end
      
      it "should produce 1 transaction activity: only to deduct the defaultee's $$$" + 
          " + "  + 
          " 2 transaction entries: to deduct the compulsory savings and voluntary savings" + 
          'should deduct the defaultee\'s compulsory savings and extra savings'  do 
          
        active_glm_count = @group_loan.active_group_loan_memberships.count
        
        @defaultee_glm = GroupLoanMembership.find(:first, :conditions => {:id=> @defaultee_glm_id_list.first })
        initial_compulsory_savings = @defaultee_glm.member.saving_book.total_compulsory_savings
        initial_extra_savings = @defaultee_glm.member.saving_book.total_extra_savings 
        
        @group_loan.execute_default_payment_execution( @cashier ) 
        @group_loan.is_default_payment_resolution_approved.should be_true
        
        puts "******** THE amount to be paid: #{@defaultee_glm.default_payment.amount_to_be_paid.to_s}"
        puts "total savings: #{@defaultee_glm.member.saving_book.total.to_s}"
        puts "total compulsory savings: #{@defaultee_glm.member.saving_book.total_compulsory_savings.to_s}"
        puts "total extra savings: #{@defaultee_glm.member.saving_book.total_extra_savings.to_s}"
        puts "unpaid backlogs: #{@group_loan.unpaid_backlogs.count }"
        
        @defaultee_glm.reload 
        final_compulsory_savings = @defaultee_glm.member.saving_book.total_compulsory_savings
        final_extra_savings = @defaultee_glm.member.saving_book.total_extra_savings
        
        diff_compulsory_savings =  initial_compulsory_savings - final_compulsory_savings
        diff_extra_savings = initial_extra_savings - final_extra_savings 
        
        puts "222compulsory savings to be deducted: #{@defaultee_glm.default_payment.amount_of_compulsory_savings_deduction.to_s}"
        puts "extra savings to be deducted: #{@defaultee_glm.default_payment.amount_of_extra_savings_deduction.to_s}"
        puts "diff compulsory: #{diff_compulsory_savings.to_s}"
        puts "diff extra: #{diff_extra_savings.to_s}"
        
        diff_compulsory_savings.should == @defaultee_glm.default_payment.amount_of_compulsory_savings_deduction 
        diff_extra_savings.should == @defaultee_glm.default_payment.amount_of_extra_savings_deduction 
        
        
        # (final_count - initial_count).should == active_glm_count
        
        @transactions = TransactionActivity.where(:loan_id => @group_loan.id , 
              :transaction_case => [ 
                TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_standard_amount],
                TRANSACTION_CASE[:default_payment_resolution_compulsory_savings_deduction_custom_amount]
                ]   )
        @transactions.length.should == active_glm_count
  
      end
      
      it 'should deduct every active glm savings according to default payment' do 
        initial_total_savings_hash = {}
        initial_compulsory_savings_hash = {}
        initial_extra_savings_hash = {}
        initial_total_savings_hash = {}
        final_compulsory_savings_hash = {} 
        final_extra_savings_hash = {} 
        final_total_savings_hash = {} 
        
        @group_loan.active_group_loan_memberships.joins(:default_payment).each do |glm|
          saving_book = glm.member.saving_book
          initial_total_savings_hash[glm.id] = saving_book.total
          initial_compulsory_savings_hash[glm.id] = saving_book.total_compulsory_savings
          initial_extra_savings_hash[glm.id] = saving_book.total_extra_savings
        end
        
        @group_loan.execute_default_payment_execution( @cashier ) 
        @group_loan.is_default_payment_resolution_approved.should be_true
        
        @group_loan.reload
        @group_loan.active_group_loan_memberships.joins(:default_payment).each do |glm|
          saving_book = glm.member.saving_book
          default_payment = glm.default_payment
          final_total_savings_hash[glm.id] = saving_book.total
          final_compulsory_savings_hash[glm.id] = saving_book.total_compulsory_savings
          final_extra_savings_hash[glm.id] = saving_book.total_extra_savings
          
          diff_total_savings = initial_total_savings_hash[glm.id] - final_total_savings_hash[glm.id]
          diff_compulsory_savings = initial_compulsory_savings_hash[glm.id] - final_compulsory_savings_hash[glm.id]
          diff_extra_savings = initial_extra_savings_hash[glm.id] - final_extra_savings_hash[glm.id]
          
          diff_total_savings.should == default_payment.amount_paid 
          diff_compulsory_savings.should == default_payment.amount_of_compulsory_savings_deduction
          diff_extra_savings.should == default_payment.amount_of_extra_savings_deduction 
        end
      end
          
      context "on group loan closing" do
        before(:each) do
          @group_loan.execute_default_payment_execution( @cashier ) 
        end
        
        it "should create N transactions where N is the number of active glm, to migrate compulsory savings to extra savings" do
          active_glm_count = @group_loan.active_group_loan_memberships.count
          puts "876 total active glm count: #{active_glm_count}"
          @group_loan.close_group_loan(@branch_manager)
          
          
          @transactions = TransactionActivity.where(:transaction_case => TRANSACTION_CASE[:port_compulsory_savings_during_group_loan_closing],
            :loan_id =>@group_loan.id)
          
          @transactions.count.should == active_glm_count
        end
        
        it "should add the amount of extra savings equal to the amount of compulsory savings" do 
          initial_extra_savings = {}
          initial_compulsory_savings = {}
          initial_total_savings = {}
          active_glm_id_list = []
          
          final_extra_savings = {}
          final_compulsory_savings = {}
          final_total_savings = {}
          
          @group_loan.active_group_loan_memberships.each do |glm|
            initial_extra_savings[glm.id] = glm.member.saving_book.total_extra_savings
            initial_compulsory_savings[glm.id] = glm.member.saving_book.total_compulsory_savings
            initial_total_savings[glm.id] = glm.member.saving_book.total 
            active_glm_id_list << glm.id 
          end
          
          
          @group_loan.close_group_loan(@branch_manager)
          
          GroupLoanMembership.where(:id =>active_glm_id_list ).each do |glm|
            final_extra_savings[glm.id] = glm.member.saving_book.total_extra_savings
            final_compulsory_savings[glm.id] = glm.member.saving_book.total_compulsory_savings
            final_total_savings[glm.id] = glm.member.saving_book.total 
          
            glm.member.saving_book.total_compulsory_savings.should == BigDecimal('0')
            (final_total_savings[glm.id] - initial_total_savings[glm.id]).should == BigDecimal("0")
            (final_extra_savings[glm.id] - initial_extra_savings[glm.id]).should == initial_compulsory_savings[glm.id]
          end
          
        end
      end
    end
    
   
    
  end# end of context 
end