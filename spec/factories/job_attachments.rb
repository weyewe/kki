FactoryGirl.define do
  factory :job_attachment do
    association :office
    user {|u| u.association(:user) }
    # name "The role"
  end
  
  # factory :branch_manager_role_assignment, parent: :assignment do |assgn|
  #     assgn.role { |role| role.association(:branch_manager_role)}
  #   end
  
  # factory :loan_officer_role_assignment, parent: :assignment do 
  #    asgn.association(:role, factory: :branch_manager_role )
  #  end
  #  
  #  factory :cashier_role_assignment, parent: :assignment do 
  #    name USER_ROLE[:cashier]
  #  end
  #  
  #  factory :field_worker_role_assignment, parent: :assignment do 
  #    name USER_ROLE[:field_worker]
  #  end
end
