Rails.application.routes.draw do
  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  scope '(:locale)', locale: /en/ do
    root to: 'pages#home'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
