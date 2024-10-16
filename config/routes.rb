SolidStorage::Engine.routes.draw do
  get "/rails/active_storage/solid_storage/:encoded_key/*filename", to: "files#show", as: :rails_service
  put "/rails/active_storage/solid_storage/:encoded_token", to: "files#update", as: :update_rails_service
end
