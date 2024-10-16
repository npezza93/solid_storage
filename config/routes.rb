Rails.application.routes.draw do
  scope ActiveStorage.routes_prefix do
    get "/solid_storage/:encoded_key/*filename", to: "files#show", as: :rails_solid_storage_service
    put "/solid_storage/:encoded_token", to: "files#update", as: :update_rails_solid_storage_service
  end
end
