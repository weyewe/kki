=begin
  We need office. 
  Every employee is locked to an office
  Every member and group is locked to an office as well
  
  One regency (kabupaten) can have many offices
  One office handles at least 1 subdistrict (kecamatan)
=end

cilincing_office = Office.create :name => "Cilincing", :regency_id => NORTH_JAKARTA_REGENCY

=begin
  We need to create the geoscope of cilincing_office
=end

java_island = Island.create :name => "Java"
jakarta_province = Province.create :name => "Jakarta", :island_id => java_island.id
north_jakarta_regency = Regency.create :name => "Jakarta Utara", :province_id => jakarta_province.id
cilincing_subdistrict = Subdistrict.create :name => "Cilincing", :regency_id => north_jakarta_regency.id

=begin
  One office handles at least one subdistrict
  Office has_many :subdistricts through :geo_scopes
=end

cilincing_office.subdistricts << cilincing_subdistrict
cilincing_office.save


=begin
  creating all villages in Cilincing subdistrict

  Kali Baru, Cilincing dengan kode pos 14110
  Cilincing, Cilincing dengan kode pos 14120
  Semper Barat, Cilincing dengan kode pos 14130
  Semper Timur, Cilincing dengan kode pos 14130
  Sukapura, Cilincing dengan kode pos 14140
  Rorotan, Cilincing dengan kode pos 14140
  Marunda, Cilincing dengan kode pos 14150
  
  http://www.jakarta.go.id/jakv1/encyclopedia/detail/202
=end

cilincing_villages = [
  {
    :postal_code => 14110,
    :name => "Kali Baru", 
    :total_communes => 14 
  },
  {
    :postal_code => 14120,
    :name => "Cilincing", 
    :total_communes => 10
  },
  {
    :postal_code => 14130,
    :name => "Semper Barat", 
    :total_communes => 17
  },
  {
    :postal_code => 14130,
    :name => "Semper Timur", 
    :total_communes => 10
  },
  {
    :postal_code => 14140,
    :name => "Sukapura", 
    :total_communes => 10
  },
  {
    :postal_code => 14140,
    :name => "Rorotan", 
    :total_communes => 11
  },
  {
    :postal_code => 14150,
    :name => "Marunda", 
    :total_communes => 9
  }
]



cilincing_villages.each do |village|
  new_village = Village.create :name => village[:name], :postal_code => village[:postal_code], 
      :subdistrict_id => cilincing_subdistrict.id

  (1..village[:total_communes]).each do |x|
    Commune.create :village_id => new_village.id , :number => x 
  end
end

first_village = Village.first
# first_village.communes.create :number => 1


puts "Done creating regional master data"
=begin
Role creation
What are the roles in typical branch? 
1. Branch Manager
  -> Approve Group Creation
  -> Approve GroupLoan Disbursement 
  -> Approve Member Creation
  -> Closing Group Loan 
    - approve that everyone has paid
  -> Create Loan Product 
  -> Updating, cancelling all these informations 
  
  -> Add employee
    -> add role 
  -> Add greographical work scope (Kecamatan)
  
  
  Branch manager only acts as controller. Making sure that everyone is doing the right thing,
  and making the critical decision
  
2. Loan Officer
  -> Registering approved member
  -> Create group    
    -> Assign member to a group -> Pick a group leader 
    
  -> Create subgroup    
    -> Assign group member to the subgroup   -> Pick the subgroup leader
  
    
  
3. Field Worker 
  -> Add Payment
    Group Creation Payment:
    -> Admin Fee 
    -> Initial Savings
    
    Weekly Payment:
    -> Savings
    -> Principal
  
  -> Add Weekly Meeting 
    -> Meeting attendance
    
4. Cashier 
  -> Approve weekly payment 
  -> Unapprove weekly payment 
    -> resolve with the responsible field worker 
=end

Role.all.each { |role| role.destroy }

branch_manager_role = Role.create :name => "BranchManager"
loan_officer_role   = Role.create :name => "LoanOfficer"
field_worker_role   = Role.create :name => "FieldWorker"
cashier_role         = Role.create :name => "Cashier"

=begin
  Create the blank slate user 
=end
puts "Gonna create user "
branch_manager = User.create :email => "branch_manager@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
                  
puts "Branch manager id is #{branch_manager.id}"

loan_officer = User.create :email => "loan_officer@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
                  
cashier = User.create :email => "cashier@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234" #, :office_id => cilincing_office.id

field_worker = User.create :email => "field_worker@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234"# , :office_id => cilincing_office.id
      
puts "Done creating user. Gonna create job_attachment"            
=begin
  assign job_attachment to each of this user 
=end

# cilincing_office.users << branch_manager 
branch_manager_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
              :user_id => branch_manager.id, :is_active => true )
# cilincing_office.users << loan_officer 
loan_officer_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
              :user_id => loan_officer.id, :is_active => true )
# cilincing_office.users << cashier 
cashier_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
              :user_id => cashier.id, :is_active => true )
# cilincing_office.users << field_worker 
field_worker_job_attachment = JobAttachment.create(:office_id => cilincing_office.id, 
              :user_id => field_worker.id, :is_active => true )


# branch_manager = User.create :email => "branch_manager@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
# branch_manager.roles << branch_manager_role
# branch_manager.save
#                   
# loan_officer = User.create :email => "loan_officer@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
# loan_officer.roles << loan_officer_role
# loan_officer.save      
#             
#                   
# field_worker = User.create :email => "field_worker@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234"# , :office_id => cilincing_office.id
# field_worker.roles << field_worker_role
# field_worker.save                
# 
# cashier = User.create :email => "cashier@gmail.com", :password => "willy1234",
#                   :password_confirmation => "willy1234" #, :office_id => cilincing_office.id
# cashier.roles << cashier_role
# cashier.save


puts "Done creating the blank slate user  user and the job attachment "


=begin
  Gonna add roles to the job attachment 
=end

branch_manager_job_attachment.roles << branch_manager_role
branch_manager_job_attachment.save

loan_officer_job_attachment.roles << loan_officer_role
loan_officer_job_attachment.save

cashier_job_attachment.roles << cashier_role
cashier_job_attachment.save

field_worker_job_attachment.roles << field_worker_role
field_worker_job_attachment.save

puts "Done adding roles to the JobAttachment"


=begin  
  The whole business process is started by the branch manager creating 
    group loan product 
=end
puts "the first"
group_loan_product_a = GroupLoanProduct.create :principal => 20000, 
                                  :interest => 4000, 
                                  :min_savings => 8000, :total_weeks => 25 ,
                                  :admin_fee => 25000, :initial_savings => 15000,
                                  :creator_id => branch_manager.id ,
                                  :office_id => cilincing_office.id
puts "the second"
group_loan_product_b = GroupLoanProduct.create :principal => 25000, 
                                  :interest => 3000, 
                                  :min_savings => 8000, :total_weeks => 25 ,
                                  :admin_fee => 25000, :initial_savings => 20000,
                                  :creator_id => branch_manager.id,
                                  :office_id => cilincing_office.id 
                                  
puts "The third"
group_loan_product_c = GroupLoanProduct.create :principal => 40000, 
                                   :interest => 1000, 
                                   :min_savings => 8000, :total_weeks => 25 ,
                                   :admin_fee => 25000, :initial_savings => 50000,
                                   :creator_id => branch_manager.id ,
                                   :office_id => cilincing_office.id
                                  
                                
puts "done creating loan product" 

# 
# branch_manager.group_loans.create :principal => 20000, 
#                                   :interest => 4000, 
#                                   :min_savings => 8000, :total_weeks => 25 ,
#                                   :admin_fee => 25000, :initial_savings => 15000
# 
# loan_product_b = branch_manager.group_loans.create 
#                                   :principal => 25000, 
#                                   :interest => 3000, 
#                                   :min_savings => 8000, :total_weeks => 25 ,
#                                   :admin_fee => 25000, :initial_savings => 20000
#                                   
# loan_product_c = branch_manager.group_loans.create :principal => 40000, 
#                                                     :interest => 1000, 
#                                                     :min_savings => 8000, :total_weeks => 25 ,
#                                                     :admin_fee => 25000, :initial_savings => 50000
                                  
                                  

=begin
  Then, after the loan product has been created, the next role is to get member. (registering member) 
  In this scheme, the members registered by loan officer are the qualified member, 
  has been processsed offline, interviewed as well. 
  Now, someone has to create a group
  Commune == RW 
  Only people from the same commune that can borrow (group loan membership)
=end

first_village = Village.first
commune       = first_village.communes.first
if loan_officer.nil?
  puts "The loan officer is nil"
else
  puts "This is awesome"
end
first_group_loan = GroupLoan.create  :commune_id => commune.id, 
              :creator_id => loan_officer.id
              
  # auto create group name 
first_member = Member.create :name => "Tuti Astuti", 
              :id_card_no => "1233435253",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 33,
              :address => "Jalan Tikus Gang 33252 no 55",
              :creator_id => loan_officer.id,
              :office_id => cilincing_office.id

second_member = Member.create :name => "Jimmy Nastar", 
              :id_card_no => "77484",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 23,
              :address => "Jalan Tikus Gang 33252 no 55",
              :creator_id => loan_officer.id,
              :office_id => cilincing_office.id
              
third_member = Member.create :name => "Astari Widayanti", 
              :id_card_no => "66343",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 11,
              :address => "Jalan Tikus Gang 33252 no 55",
              :creator_id => loan_officer.id,
              :office_id => cilincing_office.id
              
fourth_member = Member.create :name => "Jimmy Wales", 
              :id_card_no => "6634343",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 17,
              :address => "Jalan Tikus Gang 33252 no 59",
              :creator_id => loan_officer.id,
              :office_id => cilincing_office.id
              
puts "DONe creating the member"

=begin
  After the members are created, we need to assign them into the group,
  in which they share the same Commune ID, 
  in which they will be applying for loans together 
=end
              
# => assume that they are residing in the same RW
first_group_loan.members << first_member
first_group_loan.members << second_member
first_group_loan.members << third_member
first_group_loan.save

puts "Done assigning member to the group"

# => now the first_group has 3 members

=begin
  After the group has been created, loan product has to be created.
  What is the relation between branch manager and the group_loan? 
  branch manager has_many :group_loans ? 
  one group loan only belongs to one branch manager. nobody eles 
  
  THIS IS THE FUCKING GROUP LOAN
=end
# 
# loan_product_a = branch_manager.group_loans.create :principal => 20000, 
#                                   :interest => 4000, 
#                                   :min_savings => 8000, :total_weeks => 25 ,
#                                   :admin_fee => 25000, :initial_savings => 15000
# 
# loan_product_b = branch_manager.group_loans.create :principal => 25000, 
#                                   :interest => 3000, 
#                                   :min_savings => 8000, :total_weeks => 25 ,
#                                   :admin_fee => 25000, :initial_savings => 20000
#                                   
# loan_product_c = branch_manager.group_loans.create :principal => 40000, 
#                                   :interest => 1000, 
#                                   :min_savings => 8000, :total_weeks => 25 ,
#                                   :admin_fee => 25000, :initial_savings => 50000
#                                   
# puts "Done creating loan product"
# next, each group membership has to be assigned loan_product

=begin
  After assigning member to the group, 
  we should assign the loan product to each member in the group
=end



puts "Gonna assign loan product to the group_loan_membership"
group_loan_product_1 = GroupLoanProduct.find 1
group_loan_product_2 = GroupLoanProduct.find 2

first_member = Member.find 1
second_member = Member.find 2
third_member = Member.find 3 
fourth_member = Member.find 4

puts "Gonna create the first group_loan"

if branch_manager.nil?
  puts "Fuck, the branchmanager is nil"
else
  puts "nothing is wrong, the id of branch_manager is #{branch_manager.id}"
  puts "#{branch_manager.inspect}"
end
group_loan = GroupLoan.create :commune_id => first_member.commune_id , :name => "Group1", 
      :creator_id => branch_manager.id ,
      :office_id => cilincing_office.id

puts "Gonna create the GroupLoanMembership"
first_membership = GroupLoanMembership.create_membership( loan_officer, first_member, group_loan)
second_membership = GroupLoanMembership.create_membership( loan_officer, second_member, group_loan)
third_membership = GroupLoanMembership.create_membership( loan_officer, third_member, group_loan)
fourth_membership = GroupLoanMembership.create_membership( loan_officer, fourth_member, group_loan)


puts " Gonna create the group_loan_subcription "
first_subcription = GroupLoanSubcription.create_or_change( group_loan_product_1.id,  first_membership.id )
second_subcription = GroupLoanSubcription.create_or_change( group_loan_product_1.id, second_membership.id )
third_subcription = GroupLoanSubcription.create_or_change( group_loan_product_2.id, third_membership.id )
 # we leave the fourth membership's group loan as empty 




puts "8234 ---- stuck over here"# 
# first_group_loan_membership = first_group_loan.get_membership_for_member( first_member )
# second_group_loan_membership = first_group_loan.get_membership_for_member( second_member )
# third_group_loan_membership = first_group_loan.get_membership_for_member( third_member )
# 
# loan_officer.assign_group_loan_product( first_membership,  group_loan_product_a )
# # loan_officer.assign_product( second_membership,  loan_product_b )
# # loan_officer.assign_product( third_membership,  loan_product_c )

puts "Done assigning loan product to the membership "

puts "_____________FUCKING DONE WITH THE BASIC_____"

puts "The steps of group loan start?"

puts "How do we model payment"
=begin
  One TransactionActivity has many Payments 
  example, the member gives 50,000 rupiah to field worker
    it can be for 4 payments:
    1. 20,000 cash is the principal payment
    2. 5000 cash is the fine (late payment )
    3. 20,000 cash is for the savings payment 
    4. 5,0000 cash is for the interest payment
    
  But, it can only happen that one TransactionActivity contains less than 4 payments:
  example: not enough money (just 4000).  so, the member asked the worker to do: 
  Basic payment: 25k (20k == principal, 5k == interest)
  Transaction:
  1. Take 21k cash from savings account (saving credit)
  2. Pay 20k for principal
  3. Pay 5k for interest
=end


# These shites are not done 

# 
# =begin
#   after all deposit, cashier has to approve the deposit 
#   cashier doesn't go into the details of who paid how much.
#   As far as cashier is concerned, he only cares that all money information is true. 
# =end 
# cashier.approve_deposit( first_group )
# cashier.approve_initial_savings( first_group )
# cashier.approve_admin_fee( first_group )
# 
# # after cashier has approved the deposit, the branch manager will be notified
# # branch manager has to approve the shit as well 
# branch_manager.approve_loan_disbursement( first_group )
# # loan_is_started .. auto generate 25 weekly attendance for each group membership
# # auto generate 25 weekly payments for each group membership
# 
# 
# # after branch manager approval, cashier will distribute the money (in the office)
# # accompanied by the related field_worker 
# 
# cashier.disburse_loan( first_membership )
# cashier.disburse_loan( second_membership )
# cashier.disburse_loan( third_membership )
# 
# 
# 
# =begin
#   Done. With the loan financial information + deposit, the field worker will have 
#   information to select the group leader, create subgroup, and create subgroup leader
# =end
# 
# field_worker.set_group_leader( first_group, first_member) 
# 
# first_subgroup = first_group.subgroups.create 
# second_subgroup = first_group.subgroups.create 
# third_subgroup = first_group.subgroups.create 
# 
# first_subgroup.add_member( first_membership ) 
# second_subgroup.add_member( second_membership )
# third_subgroup.add_member( third_membership )
# 
# first_subgroup.set_leader( first_membership ) 
# second_subgroup.set_leader( second_membership )
# third_subgroup.set_leader( third_membership )
# 
# 
# =begin
#   DONE, they can take weekly payment. 
#   The week when the money was disbursed == week 0
#   The first week will begin in the week after 
#   
#   LOAN PAYMENT! + PAYMENT LOGIC
# =end
# 
# 
# # loan_product_a = branch_manager.group_loans.create :principal => 20000, 
# #                                   :interest => 4000, 
# #                                   :min_savings => 8000, :total_weeks => 25 ,
# #                                   :admin_fee => 25000, :initial_savings => 15000
# # with this information, minimal weekly payment is 20000 + 4000 + 8000 == 32000
# 
# # => case 1 #=> normal minimum payment
# field_worker.add_weekly_payment( first_membership , 32000 )
#   # => in the backend, payment is created 
#   # => principal == 20000, status = NORMAL_PAYMENT
#   # => savings is added  == 8000
#   # => interest is added == 4000 
#   
# # => case 2 # => less than minimum payment
# field_worker.add_weekly_payment( first_membership,  28000 )
#   # => in the backend:
#   # => in the membership => status = BUFFER_PAYMENT
#   # => principal => unpaid, status =  LESS_THAN_NORMAL
#   # => savings  # => added by 28000
#   # => interest is not added
#   
# # => case 3 # => multiple weeks payment
# field_worker.add_multiple_weeks( first_membership , 90000)
#   # => in the backend
#   # => find the total number of weeks of weekly minimum
#     # => in this case, we have 2 weeks( 64k, + extra 28k)
#     # => payment for 2 weeks will be generated
#     # => interest for 2 weeks will be generated
#     # => savings for 2 weeks will be generated + extra 28K
# 
# # => case 4 # => late payment
# field_worker.add_weekly_payment( first_membership, 32000, 2000 ) # membership, payment, fine
#   # => in the backend:
#   # => principal == 20000, status = LATE_PAYMENT
#   # => savings added == 8000
#   # => interest added = 4000
#   
# # => case 5 # => payment using voluntary savings
# field_worker.add_full_payment_with_voluntary_savings( first_membership )
#   # in the backend
#   # => principal = 20000, status = FULL_VOLUNTARY_SAVINGS
#   # => savings added == 8000, savings reduced == min payment
#   # => interest added = 4000
# 
# # => case 6 # => partial payment with voluntary and cash
# field_worker.add_partial_payment_with_voluntary_savings( first_membership, 20000)
# # in the backend
# # => principal = 2000, status = PARTIAL_PAYMENT
# # => savings added == 8000, savings reduced  = min-payment - payment
# # => interest_added = 4000
# 
# # what is the case to give fine?
# 
# =begin
#   Weekly payment is done. 
#   But, attendance has to be recorded
# =end
# 
# field_worker.add_attendance( membership, true_or_false )
# # => in the backend, there will be weekly history
# 
# =begin
#   After taking the weekly payment, field worker has to cash in the money to the cashier.
#   We are shifting the $$ amount to the cashier. But, the responsibility of the $$ distribution
#   in the group membership belongs to the field worker s
# =end
# 
# cashier.approve_weekly_payment( first_group, field_worker, description )
# # cashier.disapprove_weekly_payment( first_group, field_worker, description )
# 
# =begin
#   Finally, after 25 weeks, loan is done. 
#   There are 2 cases:
#   1. No default
#   2. Default
#   
#   For no default case, branch manager can just close the loan. 
#   Then, cashier has to return the deposit. 
#   After the disbursment of deposit, branch manager will finalize the closing 
# 
#   What if there are defaults? DEEP SHIT
#   1. Default resolution: 
#   calculate default, default payment will happen from 
#     group deposit and group savings 
#     
# =end
# 
# branch_manager.calculate_default_loan_resolution( first_group )
# # only shows the calculation, about how much money will be taken from the deposit
# # and the money will be taken from the savings account
# 
# 
# branch_manager.execute_default_loan_resolution( first_group )
# 
#   
#   
# 















