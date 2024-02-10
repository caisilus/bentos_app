class Species < ApplicationRecord
  has_many :observations
  has_many :species, through: :places
end
