FactoryGirl.define do
  factory :village do
    name ""
    postal_code "25234"
    # postal_code 
    # total_communes
  end

  # create 1  village.. and later 1 commune.. just for the sake of testing
  factory :kalibaru_village , parent: :village do 
    # postal_code '14110'
    name "Kali Baru"
    postal_code "14110"
    association :subdistrict, factory: :cilincing_subdistrict 
  end
 
  
end

