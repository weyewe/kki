FactoryGirl.define do
  factory :group_loan_product_a, class: GroupLoanProduct do
    principal 20000
    interest 8000
    min_savings 5000
    admin_fee  50000
    initial_savings 15000
    total_weeks 5
    # :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  end
  
  factory :group_loan_product_b, class: GroupLoanProduct do
    principal 50000
    interest 10000
    min_savings 10000
    admin_fee  15000
    initial_savings 30000
    total_weeks 5
    # :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  end
  
  factory :group_loan_product_c, class: GroupLoanProduct do
    principal 40000
    interest 10000
    min_savings 8000
    admin_fee  5000
    initial_savings 15000
    total_weeks 5
    # :principal, :interest, :min_savings, :admin_fee, :initial_savings, :total_weeks
  end
end