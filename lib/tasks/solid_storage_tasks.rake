desc "Copy over migrations"
namespace :solid_storage do
  task install: :environment do
    Rails::Command.invoke :generate, [ "solid_storage:install" ]
  end
end
