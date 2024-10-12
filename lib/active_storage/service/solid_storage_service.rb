require "active_storage/service"

module ActiveStorage
  class Service::SolidStorageService < ::ActiveStorage::Service
    def upload(key, io, checksum: nil, **)
      instrument(:upload, key:, checksum:) do
        SolidStorage::File.create!(key:, data: io.read)
      end
    end

    def download(key, &block)
      data = SolidStorage::File.find_by!(key:).data
      if block
        instrument(:streaming_download, key:) { yield data }
      else
        instrument(:download, key:) { data }
      end
    rescue ActiveRecord::RecordNotFound
      raise ActiveStorage::FileNotFoundError
    end

    def download_chunk(key, range)
      instrument(:download_chunk, key:, range:) do
        args =
          if sqlite? then "data, #{range.begin}, #{range.size}"
          else
           "data FROM #{range.begin} FOR #{range.size}"
          end

        SolidStorage::File.select("SUBSTRING(#{args}) as chunk").
          find_by!(key:).chunk
      end
    end

    def compose(source_keys, destination_key, **)
      SolidStorage::File.create(
        key: destination_key,
        data: SolidStorage::File.where(key: source_keys).map(&:data).join
      )
    end

    def delete_prefixed(prefix)
      instrument :delete_prefixed, prefix: do
        SolidStorage::File.where("key LIKE ?", "#{prefix}%").destroy_all
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

        payload[:url] = url_helpers.solid_storage.update_rails_url(
          verified_token_with_expiration, url_options
        )
      end
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
        raise ArgumentError, "Cannot generate URL for #{filename} using Disk service, please set ActiveStorage::Current.url_options."
      end

      url_helpers.solid_storage.rails_service_url(verified_key_with_expiration, filename: filename, **url_options)
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
  end
end
