module Api
  module V1
    class ObservationsController < ApplicationController
      # TODO: group species inside list like this: {name: "...", count: ...}
      def index
        return render json: Observation.joins(:place, :species)
                                       .select(:id, :latitude, :longtitude, "array_agg(name)")
                                       .group(:id, :latitude, :longtitude)
      end

      # TODO: validate params
      def distances
        parsed_params = parse_params
        render json: Place.joins(:species).select("id", "latitude as lat", "longtitude as long",
                                                  "array_agg(name) as species_at_place")
                                          .distances(parsed_params[:lat], parsed_params[:long])
                                          .group(:id, :lat, :long, :distance)
                                          .order(:distance)
      end

      private

      def parse_params
        params.permit(:lat, :long)
      end
    end
  end
end
