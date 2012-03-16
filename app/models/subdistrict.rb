class Subdistrict < ActiveRecord::Base
  has_many :villages
  belongs_to :regency
  
  has_many :geo_scopes
  has_many :offices, :through => :geo_scopes
end
