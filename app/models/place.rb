class Place < ApplicationRecord
  has_many :observations
  has_many :species, through: :observations
end
