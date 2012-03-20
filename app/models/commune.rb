class Commune < ActiveRecord::Base
  belongs_to :village
  
  def total_members
    Member.where(:commune_id => self.id ).count
  end
  
  def members
    Member.where(:commune_id => self.id )
  end
end
