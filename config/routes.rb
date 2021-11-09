require 'sidekiq/web'

Rails.application.routes.draw do
  use_doorkeeper do
    controllers tokens: 'tokens'
  end

  root to: 'home#index'


  devise_for :users, only: [:sessions, :authy], controllers: {devise_authy: 'devise_authy'}, :path_names => {
    verify_authy: "/verify-token",
    enable_authy: "/enable-two-factor",
    verify_authy_installation: "/verify-installation"
  }

  devise_scope :user do
    authenticate :user, lambda { |u| u.usa_admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  end

  as :user do
    get 'users/edit', to: 'users/registrations#edit', as: :edit_user_registration
    put 'users', to: 'users/registrations#update', as: :user_registration
    get 'users/password_expired', to: 'users/registrations#password_expired', as: :user_password_expired
  end


  get '/redirect', to: redirect { |params, request| "/oauth/authorize/native?#{request.params.to_query}" }

  resources :patients, only: [:index, :new, :create, :show, :edit, :update]

  resources :admin, only: [:index]
  get 'admin/users', to: 'admin#users'
  get 'admin/counts', to: 'admin#counts'

  post 'users/audits/:id', to: 'users#audits'

  post 'admin/create_user', to: 'admin#create_user'
  post 'admin/edit_user', to: 'admin#edit_user'
  post 'admin/reset_password', to: 'admin#reset_password'
  post 'admin/reset_2fa', to: 'admin#reset_2fa'
  post 'admin/email_all', to: 'admin#email_all'

  get '/jurisdictions/paths', to: 'jurisdictions#jurisdiction_paths', as: :jurisdiction_paths
  get '/jurisdictions/allpaths', to: 'jurisdictions#all_jurisdiction_paths', as: :all_jurisdiction_paths
  post '/jurisdictions/assigned_users', to: 'jurisdictions#assigned_users_for_viewable_patients', as: :assigned_users_for_viewable_patients

  get '/languages/get_all_languages', to: 'languages#language_data'
  post '/languages/translate_languages', to: 'languages#translate_language_codes'

  get '/dashboard', to: 'dashboard#dashboard', as: :dashboard

  # Errors
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unprocessable'
  get '/500', to: 'errors#internal_server_error'
end
