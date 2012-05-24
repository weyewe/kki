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
    after(:create) do |x|
      x.subdistrict = ( Subdistrict.find_by_name("Cilincing") || FactoryGirl.create(:cilincing_subdistrict) )
      x.save
    end
    # association :subdistrict, factory: :cilincing_subdistrict 
  end
 
  # village in Koja subdistrict
  # create 1  village.. and later 1 commune.. just for the sake of testing
  factory :north_koja_village , parent: :village do 
    # postal_code '14110'
    name "Koja Utara"
    postal_code "14210"
    after(:create) do |x|
      x.subdistrict = ( Subdistrict.find_by_name("Koja") || FactoryGirl.create(:koja_subdistrict) )
      x.save
    end
    # association :subdistrict, factory: :cilincing_subdistrict 
  end
end

