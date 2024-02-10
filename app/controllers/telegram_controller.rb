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

    photo_data = message["photo"].last["file_id"] # Only last photo.
    download_url = telegram_file_download_path(photo_data)
    respond_with :message, text: "Проблемы с картинкой. Попробуйте прислать другую." unless download_url

    model_output = get_model_output(download_url)
    decoded_image = Base64.decode64(model_output["image"])

    species = Species.find_by(name: model_output['predicted class'])

    observation = Observation.create(species_id: species.id)
    observation.photo.attach(
      io: StringIO.new(decoded_image),
      content_type: 'image/jpeg',
      filename: "#{photo_data["file_unique_id"]}.jpg"
    )

    response = send_photo(chat_id: message["chat"]["id"], photo: observation.photo, caption: "Результат работы модели:")
    # response = send_photo(chat_id: message["chat"]["id"], photo: observation.photo)
    puts "======================="
    puts response.code
    puts response.msg
    puts response.body
    puts "======================="

    species, encoded_image = model_output['predicted class'], model_output['image']
    respond_with :message, text: "Ваш моллюск класса #{species}"

    geolocation_request_keyboard_message
  end

  private def get_model_output(tg_photo)
    url = URI.parse(ENV["MODEL_SERVICE_URL"])

    req = Net::HTTP::Get.new(url.to_s)
    res = Net::HTTP.start(url.host, url.port) {|http|
      http.request(req)
    }

    return nil unless res.body

    JSON.parse res.body
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
