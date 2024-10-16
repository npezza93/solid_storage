require "active_storage/service"

module ActiveStorage
  class Service::SolidStorageService < ::ActiveStorage::Service
    def find(key)
      SolidStorage::File.find_by!(key:)
    end

    def upload(key, io, checksum: nil, **)
      instrument(:upload, key:, checksum:) do
        file = SolidStorage::File.create!(key:, data: io.read)
        ensure_integrity_of(key, checksum) if checksum
        file
      end
    end

    def download(key, &block)
      io = SolidStorage::File.find_by!(key:).io
      if block
        instrument(:streaming_download, key:) do
          while data = io.read(5.megabytes)
            yield data
          end
        end
      else
        instrument(:download, key:) { io.read }
      end
    rescue ActiveRecord::RecordNotFound
      raise ActiveStorage::FileNotFoundError
    end

    def download_chunk(key, range)
      instrument(:download_chunk, key:, range:) do
        args =
          if sqlite? then "data, #{range.begin + 1}, #{range.size}"
          else
           "data FROM #{range.begin + 1} FOR #{range.size}"
          end

        SolidStorage::File.select("SUBSTRING(#{args}) as chunk").
          find_by!(key:).chunk
      rescue ActiveRecord::RecordNotFound
        raise ActiveStorage::FileNotFoundError
      end
    end

    def compose(source_keys, destination_key, **)
      SolidStorage::File.create(
        key: destination_key,
        data: SolidStorage::File.where(key: source_keys).in_order_of(:key, source_keys).map(&:data).join
      )
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: do
        SolidStorage::File.where(
          SolidStorage::File.arel_table[:key].matches("#{prefix}%").to_sql
        ).destroy_all
      end
    end

    def delete(key)
      instrument(:delete, key:) { SolidStorage::File.where(key:).destroy_all }
    end

    def exist?(key)
      instrument(:exist, key:) do |payload|
        payload[:exist] = SolidStorage::File.exists?(key:)
      end
    end

    def url_for_direct_upload(key, expires_in:, content_type:, content_length:, checksum:, custom_metadata: {})
      instrument :url, key: do |payload|
        verified_token_with_expiration = ActiveStorage.verifier.generate(
          { key:, content_type:, content_length:, checksum:,
            service_name: name }, expires_in:, purpose: :blob_token
        )

        payload[:url] = url_helpers.update_rails_solid_storage_service_url(
          verified_token_with_expiration, url_options
        )
      end
    end

    def headers_for_direct_upload(key, content_type:, **)
      { "Content-Type" => content_type }
    end

    private

    def private_url(key, expires_in:, filename:, content_type:, disposition:, **)
      generate_url(key, expires_in:, filename:, content_type:, disposition:)
    end

    def public_url(key, filename:, content_type: nil, disposition: :attachment, **)
      generate_url(key, expires_in: nil, filename:, content_type:, disposition:)
    end

    def generate_url(key, expires_in:, filename:, content_type:, disposition:)
      content_disposition = content_disposition_with(type: disposition, filename:)
      verified_key_with_expiration =
        generate_key(key:, expires_in:, filename:, content_type: content_disposition, disposition:,
          purpose: :blob_key)

      if url_options.blank?
        raise ArgumentError, "Cannot generate URL for #{filename} using Solid Storage, please set ActiveStorage::Current.url_options."
      end

      url_helpers.rails_solid_storage_service_url(verified_key_with_expiration, filename: filename, **url_options)
    end

    def generate_key(key:, expires_in:, filename:, content_type:, disposition:, purpose:)
      verified_key_with_expiration = ActiveStorage.verifier.generate(
        { key:, disposition:, content_type:,
          service_name: name }, expires_in:, purpose:
      )
    end

    def sqlite?
      SolidStorage::File.connection.adapter_name == "SQLite"
    end

    def url_helpers
      @url_helpers ||= Rails.application.routes.url_helpers
    end

    def url_options
      ActiveStorage::Current.url_options
    end

    def ensure_integrity_of(key, checksum)
      unless OpenSSL::Digest::MD5.base64digest(find(key).data) == checksum
        delete key
        raise ActiveStorage::IntegrityError
      end
    end
  end
end
