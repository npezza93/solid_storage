require "solid_storage/version"
require "solid_storage/engine"
require "active_storage/service/solid_storage_service"

module SolidStorage
  mattr_accessor :connects_to
end
