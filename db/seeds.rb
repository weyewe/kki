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
=end

cilincing_villages = [
  {
    :postal_code => 14110,
    :name => "Kali Baru"
  },
  {
    :postal_code => 14120,
    :name => "Cilincing"
  },
  {
    :postal_code => 14130,
    :name => "Semper Barat"
  },
  {
    :postal_code => 14130,
    :name => "Semper Timur"
  },
  {
    :postal_code => 14140,
    :name => "Sukapura"
  },
  {
    :postal_code => 14140,
    :name => "Rorotan"
  },
  {
    :postal_code => 14150,
    :name => "Marunda"
  }
]



cilincing_villages.each do |village|
  Village.create :name => village[:name], :postal_code => village[:postal_code]
end

first_village = Village.first
first_village.communes.create :number => 1


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
All these roles are enough to manage branch office
=end



branch_manager = User.create :email => "branch_manager@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234", :office_id => cilincing_office.id
branch_manager.roles << branch_manager_role
branch_manager.save
                  
loan_officer = User.create :email => "loan_officer@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234", :office_id => cilincing_office.id
loan_officer.roles << loan_officer_role
loan_officer.save      
            
                  
field_worker = User.create :email => "field_worker@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234", :office_id => cilincing_office.id
field_worker.roles << field_worker_role
field_worker.save                

cashier = User.create :email => "cashier@gmail.com", :password => "willy1234",
                  :password_confirmation => "willy1234", :office_id => cilincing_office.id
cashier.roles << cashier_role
cashier.save


puts "Done creating the core user and the role assignment "
=begin
  BASIC setup is done. Now, someone has to create a group
  Commune == RW 
  Only people from the same commune that can borrow (group loan membership)
=end

first_village = Village.first
commune       = first_village.communes.first
first_group = Group.create  :commune_id => commune.id, 
              :creator_user_id => loan_officer.id
              
  # auto create group name 
first_member = Member.create :name => "Tuti Astuti", 
              :id_card_no => "1233435253",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 33,
              :address => "Jalan Tikus Gang 33252 no 55",
              :member_creator_id => loan_officer.id

second_member = Member.create :name => "Jimmy Nastar", 
              :id_card_no => "77484",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 23,
              :address => "Jalan Tikus Gang 33252 no 55",
              :member_creator_id => loan_officer.id
              
third_member = Member.create :name => "Astari Widayanti", 
              :id_card_no => "66343",  :village_id => first_village.id,
              :commune_id => commune.id, :neighborhood_no => 11,
              :address => "Jalan Tikus Gang 33252 no 55",
              :member_creator_id => loan_officer.id
              
puts "DONe creating the member"
              
# => assume that they are residing in the same RW
first_group.members << first_member
first_group.members << second_member
first_group.members << third_member
first_group.save

puts "Done assigning member to the group"

# => now the first_group has 3 members

=begin
  After the group has been created, loan product has to be created.
  What is the relation between branch manager and the group_loan? 
  branch manager has_many :group_loans ? 
  one group loan only belongs to one branch manager. nobody eles 
  
  THIS IS THE FUCKING GROUP LOAN
=end

loan_product_a = branch_manager.group_loans.create :principal => 20000, 
                                  :interest => 4000, 
                                  :min_savings => 8000, :total_weeks => 25 ,
                                  :admin_fee => 25000, :initial_savings => 15000

loan_product_b = branch_manager.group_loans.create :principal => 25000, 
                                  :interest => 3000, 
                                  :min_savings => 8000, :total_weeks => 25 ,
                                  :admin_fee => 25000, :initial_savings => 20000
                                  
loan_product_c = branch_manager.group_loans.create :principal => 40000, 
                                  :interest => 1000, 
                                  :min_savings => 8000, :total_weeks => 25 ,
                                  :admin_fee => 25000, :initial_savings => 50000
                                  
puts "Done creating loan product"
# next, each group membership has to be assigned loan_product
first_membership = first_group.get_membership_for_member( first_member )
second_membership = first_group.get_membership_for_member( second_member )
third_membership = first_group.get_membership_for_member( third_member )

loan_officer.assign_group_loan_product( first_group,  loan_product_a )
# loan_officer.assign_product( second_membership,  loan_product_b )
# loan_officer.assign_product( third_membership,  loan_product_c )

puts "Done assigning loan product to the membership "

puts "First membership :#{first_membership}"
puts "First membership :#{second_membership}"
puts "First membership :#{third_membership}"


# before the group loan will be disbursed, 
# the group has to deposit $$$

# field_worker.add_deposit( first_membership,  50000)
# field_worker.add_deposit( second_membership,  10000)
# field_worker.add_deposit( third_membership,  40000)

first_membership.add_deposit( field_worker, 50000)
second_membership.add_deposit( field_worker, 10000)
third_membership.add_deposit( field_worker, 40000)

puts "Done adding deposit by field worker, on behalf of the membership"



first_membership.add_initial_saving( field_worker,  20000)
second_membership.add_initial_saving( field_worker,  20000)
third_membership.add_initial_saving( field_worker,  20000)

puts "Done adding initial saving by field worker, on behalf of the membership"


first_membership.add_admin_fee( field_worker,  25000)
second_membership.add_admin_fee( field_worker,  25000)
third_membership.add_admin_fee( field_worker,  25000)

puts "Done adding membesrhip fee by field worker, on behalf of the membership"

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















