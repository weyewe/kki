FactoryGirl.define do
  factory :island do
    name "This is island"
    
    
  end
  
  factory :java_island, parent: :island do 
    name "Java"
  end
  
  
  
end
