FactoryGirl.define do
  factory :commune do
    number ""
  end

  # create 1  village.. and later 1 commune.. just for the sake of testing
  factory :group_loan_commune , parent: :commune do 
    number "1"
    association :village, factory: :kalibaru_village 
  end
  
  
  factory :non_group_loan_commune , parent: :commune do 
    number "2"
    association :village, factory: :kalibaru_village 
  end
 
  
end

