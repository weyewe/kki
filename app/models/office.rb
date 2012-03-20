class Office < ActiveRecord::Base
  # The employee can move around offices
  # It is even possible for an employee to be registered in 2 offices 
  has_many :users, :through => :job_attachments 
  has_many :job_attachments 
  
  # The group loan created will be specific to the office
  # where the branch manager is attached at    -> GroupLoan is the product 
  has_many :group_loan_products
  has_one :cashflow_book
  
  # Groups is collection of members, each member is having one group loan 
  has_many :group_loans
  # members are registered to the office. Will only change when they move house
  has_many :members 
  
  
  has_many :transaction_activities 
  
  # Normally, 1 Office represents 1 Subdistrict  
  has_many :subdistricts, :through => :geo_scopes
  has_many :geo_scopes
  
  def all_communes_under_management
    subdistricts = self.subdistricts.includes(:villages => [:communes] ) 
    puts "good with subdistricts"
    result = []
    subdistricts.each do |subdistrict|
      subdistrict.villages.each do |village| 
        village.communes.each do |commune|
          result << [ "#{subdistrict.name}, #{village.name} -- RW #{commune.number }" , 
                          commune.id ]
        end
      end
    end
    return result 
  end
  
  def active_group_loans
    self.group_loans.where(:is_closed => false )
  end
  
end
