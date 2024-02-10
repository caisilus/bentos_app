class CreateJoinTableObservationSpecies < ActiveRecord::Migration[7.1]
  def change
    create_join_table :observations, :species do |t|
      t.index [:observation_id, :species_id]
      t.index [:species_id, :observation_id]
    end
  end
end
