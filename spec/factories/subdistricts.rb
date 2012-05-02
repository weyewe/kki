FactoryGirl.define do
  factory :subdistrict do
    # how can we link to other factories ? T__T fuck fuck fuck
    name   "Subdistrict Name"
    # association :regency, factory :north_jakarta_regency
  end
  
  factory :cilincing_subdistrict , parent: :subdistrict do
    name "Cilincing"
    association :regency, factory: :north_jakarta_regency
  end
end