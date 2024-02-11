Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"
  telegram_webhook TelegramController

  namespace :api do
    namespace :v1 do
      resources :observations, only: [:index, :show]
    end
  end
end
