class Observation < ApplicationRecord
  belongs_to :species
  belongs_to :place
end
