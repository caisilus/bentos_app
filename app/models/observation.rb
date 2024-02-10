class Observation < ApplicationRecord
  has_and_belongs_to_many :species
  belongs_to :place, optional: true
  has_many_attached :photos
end
