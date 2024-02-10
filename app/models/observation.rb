class Observation < ApplicationRecord
  belongs_to :species
  belongs_to :place
  has_one_attached :photo
end
