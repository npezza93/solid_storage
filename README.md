# Solid Storage

Active Storage service adapter that stores blobs in the database and serves
them using X-Sendfile.

## Installation

1. `bundle add solid_storage`
2. `bin/rails solid_storage:install`

This will configure Solid Storage as an Active Storage adapter by overwritting `config/storage.yml`, create `db/storage_schema.rb`, and set the production adapter to `:solid_storage`.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
