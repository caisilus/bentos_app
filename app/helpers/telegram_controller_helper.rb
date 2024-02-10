module TelegramControllerHelper
  def bot_token
    Rails.application.credentials[:telegram][:bot]
  end

  def telegram_file_download_path(file_id)
    file_info = Telegram.bot.get_file(file_id: file_id)
    file_path = file_info['result']['file_path']
    "https://api.telegram.org/file/bot#{bot_token}/#{file_path}"
  end
end
