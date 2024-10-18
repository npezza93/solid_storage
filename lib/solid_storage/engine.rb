module SolidStorage
  class Engine < ::Rails::Engine
    isolate_namespace SolidStorage

    config.solid_storage = ActiveSupport::OrderedOptions.new

    initializer "solid_storage.config" do
      config.solid_storage.each do |name, value|
        SolidStorage.public_send(:"#{name}=", value)
      end
    end
  end
end
