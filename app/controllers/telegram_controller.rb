require 'net/http'

class TelegramController < Telegram::Bot::UpdatesController
  include Telegram::Bot::UpdatesController::MessageContext
  include TelegramControllerHelper

  def message(message)
    puts message
    if message['photo'].nil?
      return respond_with :message, text: "Нераспознанная команда. Ожидается фото моллюска."
    end

    download_url = telegram_file_download_path(message['photo'].last['file_id']) # Only last photo.
    respond_with :message, text: "Проблемы с картинкой. Попробуйте прислать другую." unless download_url
    model_output = get_model_output(download_url)

    respond_with :message, text: "Не могу распознать моллюска" unless model_output

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
