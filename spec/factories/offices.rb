FactoryGirl.define do
  factory :office do
    name  "Office Name"
  end
  
  factory :cilincing_office , parent: :office do
    name "Cilincing Office"
  end
end

