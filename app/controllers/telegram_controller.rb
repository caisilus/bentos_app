class TelegramController < Telegram::Bot::UpdatesController
  def message(message)
    if message['photo'].nil?
      return respond_with :message, text: "Нераспознанная команда. Ожидается фото моллюска."
    end

    session['image'] = message['photo']
    respond_with :message, text: message['text']
  end
end
