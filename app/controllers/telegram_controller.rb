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

  def message(message)
    if message['photo'].nil?
      return respond_with :message, text: "Нераспознанная команда. Ожидается фото моллюска."
    end

    photos = filter_photos(message["photos"])
    photo_urls = photos.map { |photo| telegram_file_download_path(photo["file_id"]) }

    puts photo_urls

    respond_with :message, text: "Проблемы с картинкой. Попробуйте прислать другую." unless photo_urls.any?

    respond_with :message, text: "Модель обрабатывает запрос, подождите..."

    observation = Observation.create

    model_output = get_model_output(photo_urls)
    update_observation_data(photos, model_output, observation)

    if observation.photos.count == 0
      return respond_with :message, text: "Не удалось распознать моллюсков на фото."
    else
      observation.photos.each do |photo|
        response = send_photo(chat_id: message["chat"]["id"], photo: photo,
                              caption: "Результат работы модели:")
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

      filtered_photos[index] = photo if photo["file_size"] > filtered_photos[index]
    end

    filter_photos.values
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
    model_output.each_with_index do |json, i|
      species_names = json["detections"].map {|detection| detection['name']}

      species = Species.find_or_create_by(name: species_names)
      species.each { |sp| observation.species << sp }

      observation.attach_base64_photo(json["image"], "#{photos[i]["file_unique_id"]}.jpg")
    end
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
      answer_callback_query "Отправьте геолокацию!"
    when "geo_decline"
      answer_callback_query "Не нужна мне твоя геолока!"
    end
  end

  def geolocation_await()
    unless update["message"] && update["message"]["location"]
      return respond_with :message, text: "Ожидается геолокация."
    end

    location = update["message"]["location"]

    return respond_with :message, text: "Не могу определить географические коррдинаты :(" unless location

    observation = Observation.find_by_id(session["observation_id"])
    place = Place.create(latitude: location["latitude"], longtitude: location["longitude"])
    observation.place = place if observation

    respond_with :message, text: "Место наблюдения моллюсков #{location["latitude"]}, #{location["longitude"]} " +
                                 "добавлено в базу данных"
  end
end
