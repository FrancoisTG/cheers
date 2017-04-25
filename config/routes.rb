Rails.application.routes.draw do
  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  scope '(:locale)', locale: /en/ do

    resources :hangouts do
      resources :confirmations, only: [:new, :create, :edit, :update, :destroy]
    end


    root to: 'pages#home'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
