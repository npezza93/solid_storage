# frozen_string_literal: true

class SolidStorage::FilesController < ActiveStorage::DiskController
  def show
    if key = decode_verified_key
      @file = named_disk_service(key[:service_name]).find(key[:key])
      serve_file @file, content_type: key[:content_type],
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

  private

  def serve_file(file, content_type:, disposition:)
    send_file file.tempfile,
      type: content_type || DEFAULT_SEND_FILE_TYPE,
      disposition: disposition || DEFAULT_SEND_FILE_DISPOSITION,
      file_name: params[:filename]
  end
end
