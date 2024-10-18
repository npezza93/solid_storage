# frozen_string_literal: true

class SolidStorage::InstallGenerator < Rails::Generators::Base
  source_root File.expand_path("templates", __dir__)

  def copy_files
    template "db/storage_schema.rb"
    template "config/storage.yml", force: true

    gsub_file("config/environments/production.rb", /config.active_storage.service = .*$/) do
      "config.active_storage.service = :solid_storage"
    end
  end
end
