require 'net/http'
require 'uri'

class TelegramController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include Telegram::Bot::UpdatesController::Session

  include TelegramControllerHelper

  def start!(*)
    respond_with :message, text: "Здравствуйте! Для начала работы, отправьте фотографию моллюска, " +
                                 "найденного на побережье Азовского Моря!"
  end

  def data!()
    save_context :species_name_sent
    respond_with :message, text: "Введите полное название вида моллюска"
  end

  def species_name_sent(*)
    unless update["message"] && update["message"]["text"]
      return respond_with :message, text: "Ожидается текстовое сообщение с названием моллюск."
    end

    name = update["message"]["text"]
    species = Species.find_by(name: name)

    unless species
      save_context :species_name_sent
      return respond_with :message, text: "Неизвестный вид. Попробуйте другой"
    end

    data = species.observations.joins(:place)

    puts data
    write_to_csv(data)
    respond_with :message, text: "Dummy"
  end

  private def write_to_csv(data, filename: "data.csv", separator: ",")
    File.open(filename, "w") do |f|
      headers = %w[observation place_id latitude longitude]
      f.write headers.join(separator) + "\n"
      data.each do |row|
        csv_row = [row.id, row.place.id, row.place.latitude, row.place.longtitude]
        f.write csv_row.join(separator) + "\n"
      end
    end
  end

  def message(message)
    if message['photo'].nil?
      return respond_with :message, text: "Нераспознанная команда. Ожидается фото моллюска."
    end

    photos = filter_photos(message["photo"])
    photo_urls = photos.map { |photo| telegram_file_download_path(photo["file_id"]) }

    puts photo_urls

    respond_with :message, text: "Проблемы с картинкой. Попробуйте прислать другую." unless photo_urls.any?

    respond_with :message, text: "Модель обрабатывает запрос, подождите..."

    observation = Observation.create

    model_output = get_model_output(photo_urls)
    species_names = update_observation_data(photos, model_output, observation)

    if observation.photos.count == 0
      return respond_with :message, text: "Не удалось распознать моллюсков на фото."
    else
      observation.photos.each do |photo|
        response = send_photo(chat_id: message["chat"]["id"], photo: photo,
                              caption: "Результат работы модели: #{species_names.join(", ")}")
      end
    end

    session["observation_id"] = observation.id
    geolocation_request_keyboard_message
  end

  private def filter_photos(photos)
    filtered_photos = {}

    photos.each do |photo|
      index = photo["file_id"]

      filtered_photos[index] = photo unless filtered_photos.key? index

      filtered_photos[index] = photo if photo["file_size"] > filtered_photos[index]["file_size"]
    end

    filtered_photos.values
  end

  private def get_model_output(photo_urls)
    url = URI.parse(ENV["MODEL_SERVICE_URL"])
    puts url

    req = Net::HTTP::Post.new(url.to_s, 'Content-Type': 'application/json')
    req.body = { "url": photo_urls }.to_json

    puts "TRYING TO REQUEST"
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")

    res = http.request(req)

    return nil unless res.body

    return JSON.parse res.body
  end

  private def update_observation_data(photos, model_output, observation)
    total_species_names = []
    model_output.each_with_index do |json, i|
      species_names = json["detections"].map {|detection| detection['name']}

      species_names.each do |name|
        species = Species.find_or_create_by(name: name)
        observation.species << species
        total_species_names << name
      end

      observation.attach_base64_photo(json["image"], "#{photos[i]["file_unique_id"]}.jpg")
    end

    total_species_names.uniq
  end

  private def geolocation_request_keyboard_message
    respond_with :message, text: "Хотите ли вы оставить геометку для сохранения в базу?", reply_markup: {
                  inline_keyboard: [
                      [
                        {text: "Да", callback_data: "geo_accept"},
                        {text: "Нет", callback_data: "geo_decline"}
                      ]
                    ]
                 }
  end

  def callback_query(data)
    case data
    when "geo_accept"
      save_context :geolocation_await
      respond_with :message, text: "Отправьте геолокацию!"
      answer_callback_query "Отправьте геолокацию!"
    when "geo_decline"
      respond_with :message, text: "Сохранено без геолокации."
      answer_callback_query "Сохранено без геолокации."
    end
  end

  def geolocation_await()
    unless update["message"] && update["message"]["location"]
      return respond_with :message, text: "Ожидается геолокация."
    end

    location = update["message"]["location"]

    return respond_with :message, text: "Не могу определить географические коррдинаты :(" unless location

    observation = Observation.find_by_id(session["observation_id"])
    puts "OBSERVATION:"
    puts observation
    place = Place.create(latitude: location["latitude"], longtitude: location["longitude"])
    observation.place = place if observation
    observation.save

    respond_with :message, text: "Место наблюдения моллюсков #{location["latitude"]}, #{location["longitude"]} " +
                                 "добавлено в базу данных"
  end
end
