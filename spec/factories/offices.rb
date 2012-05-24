FactoryGirl.define do
  factory :office do
    name  "Office Name"
  end
  
  factory :cilincing_office , parent: :office do
    name "Cilincing Office"
    
    after(:create) do |x|
      x.regency_id =  ( Regency.find_by_name("Jakarta Utara") || FactoryGirl.create(:north_jakarta_regency) ).id
      x.subdistricts  << ( Subdistrict.find_by_name("Cilincing")  || FactoryGirl.create(:cilincing_subdistrict)  )
      x.save
    end
  end
end

