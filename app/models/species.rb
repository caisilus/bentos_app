class Species < ApplicationRecord
  has_and_belongs_to_many :observations
  validates :name, uniqueness: true

  def get_data_for_csv
    observations.joins(:place)
  end
end
