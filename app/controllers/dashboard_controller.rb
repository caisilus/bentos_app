class DashboardController < ApplicationController
  include DashboardHelper

  def index
    csv_data = generate_csv

    headers['Content-Type'] = 'text/csv'
    headers['Content-Disposition'] = 'attachment; filename="data.csv"'
    # Send the CSV data as the response
    render plain: csv_data
  end

  def show
    species = Species.find_by_id(params[:id])

    csv_data = generate_csv_for_species(species.get_data_for_csv)

    headers['Content-Type'] = 'text/csv'
    headers['Content-Disposition'] = 'attachment; filename="data.csv"'
    # Send the CSV data as the response
    render plain: csv_data
  end
end
