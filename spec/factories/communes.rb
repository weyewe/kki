FactoryGirl.define do
  factory :commune do
    number ""
  end

  # create 1  village.. and later 1 commune.. just for the sake of testing
  factory :group_loan_commune , parent: :commune do 
    number "1"
    after(:create) do |x|
      x.village=  ( Village.find_by_name("Kalibaru") || FactoryGirl.create(:kalibaru_village) )
      x.save
    end
    
  end
  
  
  factory :non_group_loan_commune , parent: :commune do 
    number "2"
    after(:create) do |x|
      x.village =  (Village.find_by_name("Kalibaru") || FactoryGirl.create(:kalibaru_village))
      x.save
    end
  end
 
  
end

