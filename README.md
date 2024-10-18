# Solid Storage

Solid Storage is an Active Storage service adapter that stores blobs in the
database and serves them using X-Sendfile and adheres to the Active Storage
service contract.

## Why?

S3, Azure, R2, GCS all cost money. When starting out and trying to keep costs
low storing files in the database is just fine. So why not just use the disk
adapter? The disk adapter only works if you are on a single server, and if you
are on a single server, the disk adapter can be cumbersome to backup. With
data in the database, it is easy to backup and make your portal. Solid Storage
also uses X-Sendfile just like the disk adapter so you get all the upside of the
disk adapter.

## Installation

1. `bundle add solid_storage`
2. `bin/rails solid_storage:install`

This will configure Solid Storage as an Active Storage adapter by overwritting `config/storage.yml`, create `db/storage_schema.rb`, and set the production adapter to `:solid_storage`.

You will then have to add the configuration for the storage database in `config/database.yml`. If you're using SQLite, it'll look like this:

```yaml
production:
  primary:
    <<: *default
    database: storage/production.sqlite3
  storage:
    <<: *default
    database: storage/production_strorage.sqlite3
    migrations_paths: db/storage_migrate
```

...or if you're using MySQL/PostgreSQL/Trilogy:

```yaml
production:
  primary: &primary_production
    <<: *default
    database: app_production
    username: app
    password: <%= ENV["APP_DATABASE_PASSWORD"] %>
  cable:
    <<: *primary_production
    database: app_production_storage
    migrations_paths: db/storage_migrate
```

Then run `db:prepare` in production to ensure the database is created and the schema is loaded.

It's also recommended to move Active Storage models into the `storage` database
as well by adding an initializer:
```ruby
ActiveSupport.on_load(:active_storage_record) do
  connects_to(database: { writing: :storage })
end
```

## Configuration

Options are set with `config.solid_storage`.

The options are:

- `connects_to` - set the Active Record database configuration for the Solid Storage models. All options available in Active Record can be used here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
