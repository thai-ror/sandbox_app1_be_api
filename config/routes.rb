Rails.application.routes.draw do
  resources :auth, path: "/" do
    collection do
      post :auth
      post :store
      post :sign_in
      post :sign_up
      post :sign_out
    end
  end
end
