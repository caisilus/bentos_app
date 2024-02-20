class Species < ApplicationRecord
  has_and_belongs_to_many :observations
  has_many :places, through: :observations
  validates :name, presence: true, uniqueness: true

  def get_data_for_csv
    # observations.joins(:place)
    observations.joins(:place).includes(:place)
  end
end
