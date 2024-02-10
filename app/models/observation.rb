class Observation < ApplicationRecord
  belongs_to :species
  belongs_to :place, optional: true
  has_one_attached :photo
end
