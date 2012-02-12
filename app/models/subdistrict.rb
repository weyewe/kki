class Subdistrict < ActiveRecord::Base
  has_many :villages
  belongs_to :regency
  
  has_many :geoscopes
  has_many :offices, :through => :geo_scopes
end
