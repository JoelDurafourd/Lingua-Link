Rails.application.routes.draw do
  mount ActionCable.server => '/cable'

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  resources :chat

  resources :users, only: [:show] do
    get "calendars/month", to: "calendars#month"
    get "calendars/week", to: "calendars#week"
    resources :availabilities
    resources :clients do
      resources :notes
    end
    resources :bookings do
      member do
        get :accept
        get :decline
      end
    end
  end

  resources :notes

  resources :chat, only: [:index, :show] do
    collection do
      post :send_message
    end
  end


  root to: "pages#home"

  get 'dashboard', to: 'dashboard#show', as: :dashboard
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "messages/callback" => "messages#callback"
  post "messages/debug/update" => "messages#update_all_users_rich_menu"

  # Defines the root path route ("/")
  # root "posts#index"
end
