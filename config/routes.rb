Rails.application.routes.draw do
  resources 'main'
  get 'renew', to: 'main#renew_ip'
end
