FactoryGirl.define do
  factory :regency do
    # how can we link to other factories ? T__T fuck fuck fuck
    name "Regency Name"
  end
  
  factory :north_jakarta_regency, parent: :regency do 
    name "Jakarta Utara"
    after_create do |x|
      x.province = ( Province.find_by_name("DKI Jakarta") || FactoryGirl.create(:jakarta_province) )
      x.save
    end
  end
end