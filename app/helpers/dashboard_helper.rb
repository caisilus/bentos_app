require 'csv'

module DashboardHelper
  def generate_csv_for_species(data)
    headers = %w[observation place_id latitude longitude created_at]

    CSV.generate do |csv|
      csv << headers

      data.each do |row|
        csv << [row.id, row.place.id, row.place.latitude, row.place.longtitude, row.created_at]
      end
    end
  end

  def generate_csv
    headers = %w[observation place_id latitude longitude created_at specie_name]

    CSV.generate do |csv|
      csv << headers

      # find_each is better than all.each because it loads data from table in batches
      # Though in this case it doesn't matter, species is small table
      Species.find_each do |species|
        data = species.get_data_for_csv

        data.each do |row|
          csv << [row.id, row.place.id, row.place.latitude, row.place.longtitude, row.created_at, species.name]
        end
      end
    end
  end

  def write_to_csv(data, filename: "data.csv", separator: ",")
    File.open(filename, "w") do |f|
      headers = %w[observation place_id latitude longitude created_at]
      f.write headers.join(separator) + "\n"
      data.each do |row|
        csv_row = [row.id, row.place.id, row.place.latitude, row.place.longtitude, row.created_at]
        f.write csv_row.join(separator) + "\n"
      end
    end
  end
end
