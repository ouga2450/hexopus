Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Zennly APIエンドポイント（実装時に追加）
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
