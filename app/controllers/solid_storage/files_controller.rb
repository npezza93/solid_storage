# frozen_string_literal: true

class SolidStorage::FilesController < ActiveStorage::DiskController
  include ActiveStorage::FileServer

  def show
    if key = decode_verified_key
      @file = named_disk_service(key[:service_name]).find(key[:key])
      serve_file @file.tempfile, content_type: key[:content_type],
        disposition: key[:disposition]
    else
      head :not_found
    end
  end

  def update
    if token = decode_verified_token
      if acceptable_content?(token)
        named_disk_service(token[:service_name]).upload token[:key],
          request.body, checksum: token[:checksum]
        head :no_content
      else
        head :unprocessable_entity
      end
    else
      head :not_found
    end
  rescue ActiveStorage::IntegrityError
    head :unprocessable_entity
  end
end
