require 'net/http'
require 'net/http/post/multipart'
require 'uri'

module TelegramControllerHelper
  def bot_token
    Rails.application.credentials[:telegram][:bot]
  end

  def telegram_file_download_path(file_id)
    file_info = Telegram.bot.get_file(file_id: file_id)
    file_path = file_info['result']['file_path']
    "https://api.telegram.org/file/bot#{bot_token}/#{file_path}"
  end

  def telegram_file_upload_path(chat_id)
    "https://api.telegram.org/bot#{bot_token}/sendPhoto?chad_id=#{chat_id}"
  end

  # photo - active storage object
  def send_photo(chat_id:, photo:, caption: nil)
    url_str = telegram_file_upload_path(chat_id)
    url = URI.parse(url_str)

    request = Net::HTTP::Post::Multipart.new(url.path, {
      'chat_id': chat_id,
      'caption': caption,
      'photo': UploadIO.new(StringIO.new(photo.download), 'image/jpeg', 'image.jpg')
    })

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == 'https')

    http.request(request)
  end
end
