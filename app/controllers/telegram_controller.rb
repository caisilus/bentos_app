require 'net/http'
require 'uri'

class TelegramController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include TelegramControllerHelper

  def message(message)
    puts message
    if message['photo'].nil?
      return respond_with :message, text: "Нераспознанная команда. Ожидается фото моллюска."
    end

    photos = message["photo"].values_at(*(1..message["photo"].length).step(2))

    photo_urls = photos.map { |photo| telegram_file_download_path(photo["file_id"]) }
    puts photo_urls

    respond_with :message, text: "Проблемы с картинкой. Попробуйте прислать другую." unless photo_urls.any?

    observation = Observation.create

    respond_with :message, text: "Модель обрабатывает запрос, подождите..."

    model_output = get_model_output(photo_urls)
    puts "=========OUTPUT========="
    puts model_output
    model_output.each_with_index do |json, i|
      decoded_image = Base64.decode64(json["image"])
      detections = json["detections"]
      names = detections.map {|detection| detection['name']}
      species = Species.find_or_create_by(name: names)

      observation.photos.attach(
        io: StringIO.new(decoded_image),
        content_type: 'image/jpeg',
        filename: "#{photos[i]["file_unique_id"]}.jpg"
      )
    end

    if observation.photos.count == 0
      return respond_with :message, text: "Не удалось распознать моллюсков на фото."
    else
      observation.photos.each do |photo|
        response = send_photo(chat_id: message["chat"]["id"], photo: photo,
                              caption: "Результат работы модели:")
      end
    end

    geolocation_request_keyboard_message
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
    respond_with :message, text: "Вы находитесь на #{location["latitude"]}, #{location["longitude"]}"
  end
end
