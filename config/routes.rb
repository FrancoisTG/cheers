Rails.application.routes.draw do
  devise_for :users,
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  scope '(:locale)', locale: /en|pt-BR/ do

    resources :hangouts do
      resources :confirmations, only: [:new, :create, :edit, :update, :destroy]
    end

    get 'profiles/show'

    root to: 'hangouts#new'
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
