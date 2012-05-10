desc "Parse KKI real member data "

task :parse_member => :environment do 
  require 'csv'
  
  
  VILLAGE_MAPPER = {
    1            => "Kali Baru"       ,
    2            =>  "Cilincing"      ,
    3            =>   "Semper Barat"  ,
    4            => "Semper Timur"    ,
    5            =>   "Sukapura"      ,
    6            =>  "Rorotan"        ,
    7            => "Marunda"
  }
  
  filename = "group_24.csv"
  # filename = "eka_ruby_data.csv"
  loan_officer = User.find_by_email "loan_officer@gmail.com"
  cilincing_office = Office.first 
  CSV.foreach(Rails.root.to_s + "/lib/tasks/" + "#{filename}") do |row|
    name = row[0]
    uniq_id = row[1]
    address = row[2]
    village_id = row[3]
    commune_number = row[4] # link to the village id 
    neighborhood = row[5]
    
    village = Village.find_by_name( VILLAGE_MAPPER[village_id.to_i] )
    commune = village.communes.where(:number => commune_number).first
    if commune.nil? 
      puts "The commune for number #{commune_number}, village #{village_id} is nil"
    end
    
    member = Member.create :name               =>  name           ,
                                :id_card_no         =>  uniq_id        ,
                                :village_id         =>  village.id     ,
                                :commune_id         =>  commune.id     ,
                                :neighborhood_no    =>  neighborhood   ,
                                :address            =>  address        ,
                                :creator_id         =>  loan_officer.id,
                                :office_id          =>  cilincing_office.id 
      
    
  end
end
