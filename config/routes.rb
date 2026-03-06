Rails.application.routes.draw do
  if Rails.env.development?
    mount GoodJob::Engine => "/admin/good_job"
    mount Avo::Engine => "/admin"
  else
    authenticate :user, lambda { |u| u.admin? } do
      mount GoodJob::Engine => "/admin/good_job"
      mount Avo::Engine => "/admin"
    end
  end

  devise_for :users
  resources :activities, only: [ :index, :show ]
  resources :bills, only: [ :index, :show ]
  resources :feeds, only: [ :index, :show ]
  resources :entries, only: [ :index, :show ]
  resources :ministers, only: [ :index, :show ]
  resources :departments, only: [ :index, :show ]
  resources :commitments, only: [ :index, :show ] do
    resources :feed_items, only: [ :index ], path: "feed"
  end
  resources :promises, only: [ :index, :show ]
  resources :evidences, only: [ :index, :show ]
  resources :builders, only: [ :index, :show ]
  resources :statcan_datasets, only: [ :show ]
  resources :feed_items, only: [ :index ], path: "feed"

  namespace :api do
    get "burndown/:government_id", to: "burndown#show", as: :burndown
    get "dashboard/:government_id/at_a_glance", to: "dashboard#at_a_glance", as: :at_a_glance
  end

  namespace :admin do
    resources :promises, only: [ :index, :show, :update, :destroy ]
    resources :evidence, only: [ :index, :show, :update, :destroy ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  root "application#root"
end
