FactoryGirl.define do
  factory :member_of_first_rw_office_cilincing, class: Member do
      #   
      # t.string   "name"    # use faker 
      sequence :name do |n|
        "Member #{n}"
      end
      # t.string   "id_card_no"  # use sequence
      sequence :id_card_no do |n|
        "234242343#{n}"
      end
      # t.integer  "village_id" # get one we have
      # association :village, factory: :kalibaru_village
      # t.integer  "commune_id" # get the one we have
      # association :commune, factory: :group_loan_commune 
      # t.integer  "neighborhood_no" # randome.. sequence will do
      sequence :neighborhood_no do |n|
        n
      end
      # t.text     "address" # faker 
      sequence :address do |n|
        "Gang Macan 33 #{n}"
      end
      # t.integer  "creator_id" # loan_officer   -> we need to check.. will this scumbag regenerate the new loan_officer?
      
      # t.integer  "office_id"  # office -> DITTO like creator_id .. if it will, better to generate it from somewhere else 
      association :office, factory: :cilincing_office
  end
end