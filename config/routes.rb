Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  resources :users, only: [:show] do
    get "calendars/month", to: "calendars#month"
    resources :bookings do
      member do
        get :accept
        get :decline
      end
    end
  end

  resources :clients


  root to: "pages#home"

  get 'dashboard', to: 'dashboard#show', as: :dashboard
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  post "messages/callback" => "messages#line_callback"

  # Defines the root path route ("/")
  # root "posts#index"
end
