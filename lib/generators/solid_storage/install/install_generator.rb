# frozen_string_literal: true

class SolidStorage::InstallGenerator < Rails::Generators::Base
  def create_migrations
    rails_command "solid_storage:install:migrations", inline: true
  end
end
