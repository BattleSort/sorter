Rails.application.routes.draw do
  resources :rankings
  get 'room/index'
  
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'room#index'
  mount ActionCable.server => '/cable'
end
