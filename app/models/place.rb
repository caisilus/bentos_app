class Place < ApplicationRecord
  has_many :observations
  has_many :species, through: :observations

  scope :distances, -> (lat2, long2) do
    earth_radius = 6371
    select("#{earth_radius} * 2 * asin( |/(sind((#{lat2} - latitude)/2) ^ 2 +
            cosd(latitude)*cosd(#{lat2}) * sind((#{long2} - longtitude)/2)^2) ) as distance")
  end
end
