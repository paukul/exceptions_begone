ExceptionsBegone::Application.routes.draw do
  match '/' => 'projects#index'
  match 'login' => 'user_sessions#new', :as => :login
  match 'logout' => 'user_sessions#destroy', :as => :logout
  resources :user_sessions
  resources :projects do
    resources :stacks do
      resources :notifications
    end
    resources :exclusions
    resources :notifications
  end

end