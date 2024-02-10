class Species < ApplicationRecord
  has_and_belongs_to_many :observations
  validates :name, uniqueness: true
end
