class Office < ActiveRecord::Base
  has_many :users
  
  has_many :subdistricts, :through => :geo_scopes
  has_many :geo_scopes
end
