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
  ensure
    @file&.tempfile.unlink
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
    ::Rack::Files.new(nil).serving(request, file.tempfile.path).tap do |(status, headers, body)|
      self.status = status
      self.response_body = body

      headers.each do |name, value|
        response.headers[name] = value
      end

      response.headers.except!("X-Cascade", "x-cascade") if status == 416
      response.headers["Content-Type"] = content_type || DEFAULT_SEND_FILE_TYPE
      response.headers["Content-Disposition"] = disposition || DEFAULT_SEND_FILE_DISPOSITION
    end
  end
end
