require 'spec_helper'

describe DefaultPayment do
  
  context "generic case: 2 subgroups, 4-4 .. in the first subgroup, 1 default. in the second subgroup , 2 defaults" do
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

      ############ subgroup creation
      SubGroup.set_sub_groups( @group_loan, 2 ) # produce the 2 subgroups
      @first_sub_group = @group_loan.sub_groups.first
      @second_sub_group = @group_loan.sub_groups.last
      ############# end of subgroup creation

      # we need several members in a given commune   DONE 
      @members = FactoryGirl.create_list(:member_of_first_rw_office_cilincing, 8, creator_id: @loan_officer.id,
       commune_id: @group_loan_commune.id )
      # we need these members hooked to the group loan (group_loan_memberships)
      counter = 0  # for subgroup assignment
      @members.each do |member|
        counter += 1 
        glm = GroupLoanMembership.create_membership( @loan_oficer, member, @group_loan)
        ############### this code is used to assign subgroup
        if( counter%2 == 0 )
          glm.sub_group_id = @first_sub_group.id
          glm.save
        else
          glm.sub_group_id = @second_sub_group.id
          glm.save
        end
        ############# end of subgroup asssignment.
      end

      ############## subgroup code
      random_4 = rand(4)
      @sub_group_1_selected_member = @first_sub_group.group_loan_memberships[ random_4 ].member
      @sub_group_2_selected_member_1 = @second_sub_group.group_loan_memberships[ (random_4 +1 )%4].member
      @sub_group_2_selected_member_2 = @second_sub_group.group_loan_memberships[ (random_4 +2 )%4 ].member
      @special_default_member_id_list = [ @sub_group_1_selected_member.id ,
          @sub_group_2_selected_member_1.id ,
          @sub_group_2_selected_member_2.id ]
      ############## subgroup code

      @total_number_of_weeks  = 2 
      # we need group_loan_product x 3 , just for variations
      @group_loan_product_a = FactoryGirl.create(:group_loan_product_a, total_weeks: @total_number_of_weeks)
      @group_loan_product_b = FactoryGirl.create(:group_loan_product_b, total_weeks: @total_number_of_weeks)
      @group_loan_product_c = FactoryGirl.create(:group_loan_product_c, total_weeks: @total_number_of_weeks)

      #assign the group_loan_product subcription 
      group_loan_products_array  = [@group_loan_product_a, @group_loan_product_b, @group_loan_product_c]
      @members.each do |member|
         # randomized
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        GroupLoanSubcription.create_or_change( group_loan_products_array[rand(3)].id  ,  glm.id  )
      end

      #start the group loan (the approval cycle)
      @group_loan.execute_propose_finalization( @loan_officer )
      @group_loan.start_group_loan( @branch_manager )

      # puts  "At the end of the highest before block"

      # puts  "total villages : #{Village.count}"
      # puts  "total subdistricts: #{Subdistrict.count}"
      # puts  "total regencies: #{Regency.count}"
      # puts  "total provinces: #{Province.count}"
      # puts  "total island: #{Island.count}"


      # do the setup payment, finalize.. let the weekly payment begin
      @members.each do |member|
        glm = GroupLoanMembership.find(:first, :conditions => {
          :member_id => member.id,
          :group_loan_id => @group_loan.id 
        })
        glm.declare_setup_payment_by_loan_deduction
      end

      @group_loan.execute_finalize_setup_fee_collection( @field_worker )
      @group_loan.approve_setup_fee_collection( @cashier )


      # do the loan disbursement

      @group_loan.group_loan_memberships.each do |glm|
        TransactionActivity.execute_loan_disbursement( glm , @cashier )
      end

      @group_loan.execute_finalize_loan_disbursement( @cashier )



      # puts  "Total weekly Tasks: #{@group_loan.weekly_tasks.count}"

      # gonna finalize the week
      (1..(@group_loan.total_weeks )).each do |week|
        # puts  "week number: #{week}"
        weekly_task = @group_loan.currently_executed_weekly_task 
        @members.each do |member|
          value = rand(3)
          if value == 0
            weekly_task.mark_attendance_as_late(member, @field_worker )
          elsif value ==1 
            weekly_task.mark_attendance_as_present(member, @field_worker  )
          elsif value == 2 
            weekly_task.mark_attendance_as_absent(member, @field_worker  )
          end
        end
        weekly_task.close_weekly_meeting( @field_worker ) #line 350

        # create all transaction as no savings
        @savings_amount = BigDecimal("10000")
        @members.each do |member|
          if @special_default_member_id_list.include?(member.id)
            TransactionActivity.create_savings_only_weekly_payment(
              member,
              weekly_task,
              @savings_amount,
              @field_worker
            )
          else
            # create basic payment 
            TransactionActivity.create_basic_weekly_payment(
              member,
              weekly_task,
              @field_worker
            )
          end

        end
        weekly_task.close_weekly_payment( @field_worker )
        # cashier approve
        weekly_task.approve_weekly_payment_collection( @cashier )
      end
    end # end of the before(:each)

    context "testing the setup code, whether it produces what we want" do
      it "should produces 2 subgroups, each having 4 members" do
        
        @group_loan.sub_groups.count.should == 2 
        
        first_sub_group = @group_loan.sub_groups.first
        last_sub_group = @group_loan.sub_groups.last 
        
        first_sub_group.group_loan_memberships.count.should ==  4
        last_sub_group.group_loan_memberships.count.should == 4 
      end
      
      it "should have 3 * number of weeks backlog payment" do
        @group_loan.unpaid_backlogs.count.should == 3*@group_loan.total_weeks
      end
    end
    
    context "creation of default payment, pre conditions" do 
      
      it "should not create default payment if not executed by branch_manager"
      it "should not create default payment if not all weekly tasks are closed: payment and meeting"
      # @group_loan.declare_default(current_user) 
    end


    context "post conditions of default payment creation" do 
      before(:each) do
        
        @group_loan.declare_default(@branch_manager) 
        
      end
      
      it "Should have is_group_loan_default == true " do
        @group_loan.is_group_loan_default.should == true 
      end
      
      it 'should have branch manager id as the default creator id' do
        @group_loan.default_creator_id.should == @branch_manager.id
      end
      
      
      context "subgroup, generic case" do
        it "should produces default member: 1 for sub_group 1, and 2 for sub_group 2, 3 defaults for the whole group" do
          @group_loan.total_default_member.should == 3 
          @first_sub_group.total_default_member.should  == 1 
          @second_sub_group.total_default_member.should == 2 
        end
        
        it "should extract the correct total default value in subgroup, and the total group" do 
          total_group_loan_default = BigDecimal("0")
          actual_total_default = @first_sub_group.extract_total_unpaid_backlogs
          
          group_loan_product = @group_loan.get_membership_for_member( @sub_group_1_selected_member ) .group_loan_product
          expected_total_default  = @total_number_of_weeks*group_loan_product.total_weekly_payment
          actual_total_default.should == expected_total_default
          # puts  "Actual first group default:#{actual_total_default} "
          # puts  "Expected first group default: #{expected_total_default}"
          total_group_loan_default += actual_total_default
          # for the 2nd group
          actual_total_default_2 = @second_sub_group.extract_total_unpaid_backlogs
          expected_total_default_2 = BigDecimal("0")
          group_loan_product = @group_loan.get_membership_for_member( @sub_group_2_selected_member_1 ) .group_loan_product
          expected_total_default_2  += @total_number_of_weeks*group_loan_product.total_weekly_payment
          group_loan_product = @group_loan.get_membership_for_member( @sub_group_2_selected_member_2 ) .group_loan_product
          expected_total_default_2  += @total_number_of_weeks*group_loan_product.total_weekly_payment
          actual_total_default_2.should == expected_total_default_2
          # puts  "Actual second group default:#{actual_total_default_2} "
          # puts  "Expected second group default: #{expected_total_default_2}"
          total_group_loan_default += actual_total_default_2
          
          # puts  "Actual default group_loan :#{@group_loan.extract_total_default_amount}"
          puts  "The TOTAL default amount group_loan :#{@group_loan.total_default_amount}"
          @group_loan.total_default_amount.should == total_group_loan_default
        end
        
        it "should produce group total default == total default from sub groups" do
          actual_group_loan_total_default = @group_loan.extract_total_default_amount
          expected_total = BigDecimal("0")
          @group_loan.sub_groups.each do |sub_group|
            puts "subgroup #{sub_group.number}: sub_group_total_default_payment_amount: #{sub_group.sub_group_total_default_payment_amount}"
            expected_total += sub_group.sub_group_total_default_payment_amount
          end
          
          # puts  "Actual Group Default = #{actual_group_loan_total_default}"
          actual_group_loan_total_default.should == expected_total 
        end
        
        it "sould have 8-3 non-default member id " do
          @group_loan.extract_non_default_member_id.length.should == 5 
          # puts  "---!!!!!!!!!! #{@group_loan.extract_non_default_member_id}"
        end
         
        it "should produce default payment, as many as the number of group members" do
          # puts  "0000000 total default payment : #{DefaultPayment.count}"
          glm_id = @group_loan.group_loan_memberships.map {|x| x.id }
          # puts  "THE GLM ID: #{glm_id}"
          
          # list_of_non_default_member_id = @group_loan.extract_non_default_member_id
          #       @group_loan.group_loan_memberships.each do |glm|
          #         # puts  "@@@ current glm.member_id = #{glm.member_id}"
          #         if list_of_non_default_member_id.include?(glm.member_id)
          #           DefaultPayment.create :group_loan_membership_id => glm.id , :is_defaultee => false # by default 
          #         else
          #           DefaultPayment.create :group_loan_membership_id => glm.id , :is_defaultee => true 
          #         end
          #       end
          #       
          # puts  "========= total default_Paymnet = #{DefaultPayment.count}"
          
          
          # DefaultPayment.find(:all, :conditions => {
          #   :group_loan_membership_id => glm_id
          # }).count.should == @group_loan.group_loan_memberships.count 
          # puts  "============ the group_loan status : #{@group_loan.is_group_loan_default}}"
          DefaultPayment.count.should == @group_loan.group_loan_memberships.count 
          
          
        end
        
        it "should produce total of sub_group share of non defaultee == 50% total sub_group default"  do
          # puts  "Total subgroups : #{@group_loan.sub_groups.count}"
          # puts  "Total DefaultPayment: #{DefaultPayment.count}"
          @group_loan.sub_groups.each do |sub_group|
            total_sub_group = BigDecimal("0")
            # puts  "For #{sub_group.number}, total_default_payments: #{sub_group.default_payments.count}"
            sub_group.default_payments.each do |default_payment_sub_group_member|
              
              total_sub_group += default_payment_sub_group_member.amount_sub_group_share
              # puts  "The subgroup_share amount of default_payment: #{default_payment_sub_group_member.amount_sub_group_share}"
            end
            
            
            actual_total_sub_group_default_payment = sub_group.sub_group_total_default_payment_amount
            # puts  "Actual SubGroup Default  = #{ actual_total_sub_group_default_payment}"
            tolerance = (1/100.0) * ( actual_total_sub_group_default_payment/2) # 10% tolerance
            ( actual_total_sub_group_default_payment/2) .should  be_within(tolerance).of(total_sub_group)
            puts "========== summary"
            puts "50% actual total sub group default = #{actual_total_sub_group_default_payment/2}"
            puts "total sub_group = #{total_sub_group}"
            puts "the tolerance: #{tolerance}"
          end
        end
        
        it "should produce total of group_share of non_defaultee == 50% total group default" do
          total_group_loan_default = @group_loan.extract_total_default_amount
          total_sum_of_group_share = BigDecimal("0")
          @group_loan.group_loan_memberships.each do |glm|
            total_sum_of_group_share += glm.default_payment.amount_group_share
          end
          
          
          tolerance = (1/100.0) * (total_group_loan_default /2)# 10% tolerance
          (total_group_loan_default /2).should  be_within(tolerance).of(total_sum_of_group_share)
          puts "******* summary: 50% total group loan default == #{total_group_loan_default /2}"
          puts "******* summary: tolerance = #{tolerance}"
          puts "******* summary: total sum = #{total_sum_of_group_share}"
        end
        
        
        # it "should not store the after decimal point value (no floating point)" do
        # end
        # 
        
      end
      
    
      
      it "should round up total contribution, rounded up to the nearest 500 rupiah" do
        @group_loan.group_loan_memberships.each do |glm|
          default_payment = glm.default_payment
          puts "the total amount for #{default_payment.id} : #{default_payment.total_amount}"
          (  default_payment.total_amount.to_i % DEFAULT_PAYMENT_ROUND_UP_VALUE.to_i   ).should == 0 
        end
      end
      
      
    end
    
    
    
    context "paying for the default_payment" do
      before(:each) do
        
      end
      
      it "should not accept default_payment from defaultee == true , only accepts from non default"
      
      # They are transaction activities, aren't they?
      it "should accept payment by savings withdrawal, if there are enough savings" do
        
      end
      
      
      it "should accept payment by structured methods"
    end
    context "closing the default payments: office absorbs lost? "
  end # end of context "generic case"
  
  context "a subgroup with all default members" 
  context "a group with all default members"


############ general case 
# everyone in subgroup paid, exept 1 guy in subgroup 1, and 2 guys in subgroup 2.. 
# ensure that the correct default payment value is created 
# what will happen if the  non-defaultee can't pay for the default co-payment? 
# is the up-rounding to the highest 500 multiplication working ? 

############ corner cases
# => all members in 1 of the subgroup defaulted   -> what will happen ?
# => all members defaulted in the whole group loan  -> what will happen ? 

end
