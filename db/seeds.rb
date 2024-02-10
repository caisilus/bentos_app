# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

unless Place.any?
  Place.create(latitude: 40.128342, longtitude: 50.192931)
  Place.create(latitude: 32.164015, longtitude: 39.211520)
end

unless Species.any?
  Species.create(name: "Dreissena polymorpha")
  Species.create(name: "Monodacna colorata")
end

unless Observation.any?
  place1 = Place.first
  place2 = Place.second

  species1 = Species.first
  species2 = Species.second

  Observation.create(place: place1, species: [species1, species2])
  Observation.create(place: place1, species: [species2])
  Observation.create(place: place2, species: [species2])
end
