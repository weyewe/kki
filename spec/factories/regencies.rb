FactoryGirl.define do
  factory :regency do
    # how can we link to other factories ? T__T fuck fuck fuck
    name "Regency Name"
  end
  
  factory :north_jakarta_regency, parent: :regency do 
    name "Jakarta Utara"
    association :province, factory: :jakarta_province 
  end
end