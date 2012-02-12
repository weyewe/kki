class Office < ActiveRecord::Base
  has_many :users
  
  has_many :subdistricts, :through => :geoscopes
  has_many :geo_scopes
end
