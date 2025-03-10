Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  namespace :api do
    namespace :v1 do
      resources :health, only: %i[index]

      resources :auth do
        collection do
          post "login", to: "auth#login"
        end
      end

      resources :users do
        collection do
          get "me", to: "users#me"
        end
      end

      resources :socials do
        collection do
          post "follow/:user_id", to: "socials#follow"
          post "unfollow/:user_id", to: "socials#unfollow"
        end
      end
    end
  end

  # API documentation
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
end
