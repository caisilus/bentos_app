class AddUniqueIndexToSpeciesName < ActiveRecord::Migration[7.1]
  def change
    add_index :species, :name, unique: true
  end
end
