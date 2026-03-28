Rails.application.routes.draw do
  namespace :api do
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
