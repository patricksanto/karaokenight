Rails.application.routes.draw do
  root "home#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get "home/test", to: "home#test"

  resources :rooms, only: [:new, :create]
  post "rooms/enter", to: "rooms#enter", as: :enter_room
  get "rooms/:id/join", to: "rooms#join", as: :join_room

  resources :rooms, only: [] do
    resource :session, only: [:new, :create], controller: "room_sessions"

    scope module: :rooms do
      get "stage", to: "participants#stage"
      get "queue", to: "participants#queue"
      get "my-songs", to: "participants#my_songs"

      resources :song_requests, only: [:create, :destroy] do
        member do
          patch :cancel
        end
      end

      patch :toggle_availability, to: "participants#toggle_availability"

      resources :votes, only: [:create, :update]

      resources :performances, only: [] do
        member do
          post :close
          post :abort
          post :finish
        end
      end
      post "performances/start", to: "performances#start", as: :start_performance
      post "song_requests/:id/play", to: "song_requests#play", as: :play_song_request
      post "reactions", to: "reactions#create", as: :reactions
    end
  end

  get "rooms/:code/projector", to: "projector#show", as: :room_projector
  get "rooms/:code/host", to: "host#show", as: :room_host

  post "rooms/:code/host/authenticate", to: "host#authenticate", as: :authenticate_room_host
end
