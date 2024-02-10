class CreateObservations < ActiveRecord::Migration[7.1]
  def change
    create_table :observations do |t|
      t.references :species, null: false, foreign_key: true
      t.references :place

      t.timestamps
    end
  end
end
