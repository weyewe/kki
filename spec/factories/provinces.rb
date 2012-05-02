FactoryGirl.define do
  factory :province do
    # how can we link to other factories ? T__T fuck fuck fuck
    name  "Province Name"
  end
  
  factory :jakarta_province , parent: :province do
    name "DKI Jakarta"
    association :island, factory: :java_island
  end
  
  
end