Rails.application.routes.draw do
  root 'welcome#index'
  post 'welcome/get_product' => 'welcome#get_product', as: :get_product
end