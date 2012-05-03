FactoryGirl.define do
  factory :province do
    # how can we link to other factories ? T__T fuck fuck fuck
    name  "Province Name"
  end
  
  factory :jakarta_province , parent: :province do
    name "DKI Jakarta"
    after_create do |x|
      x.island = ( Island.find_by_name("Jawa") || FactoryGirl.create(:java_island) )
      x.save
    end
    
    
  end
  
  
end