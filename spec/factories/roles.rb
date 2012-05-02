FactoryGirl.define do
  factory :role do
    name "The role"
  end
  
  factory :branch_manager_role, parent: :role do 
    name USER_ROLE[:branch_manager]
  end
  
  factory :loan_officer_role, parent: :role do 
    name USER_ROLE[:loan_officer]
  end
  
  factory :cashier_role, parent: :role do 
    name USER_ROLE[:cashier]
  end
  
  factory :field_worker_role, parent: :role do 
    name USER_ROLE[:field_worker]
  end
end
