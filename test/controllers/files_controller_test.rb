require "test_helper"

class FilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveStorage::Current.url_options = { protocol: "https://", host: "example.com", port: nil }
  end

  teardown do
    ActiveStorage::Current.reset
  end

  test "showing blob inline" do
    blob = create_blob(filename: "hello.jpg", content_type: "image/jpeg")

    get blob.url
    assert_response :ok
    assert_equal "inline; filename=\"hello.jpg\"; filename*=UTF-8''hello.jpg", response.headers["Content-Disposition"]
    assert_equal "image/jpeg", response.headers["Content-Type"]
    assert_equal "Hello world!", response.body
  end

  test "showing blob as attachment" do
    blob = create_blob
    get blob.url(disposition: :attachment)
    assert_response :ok
    assert_equal "attachment; filename=\"hello.txt\"; filename*=UTF-8''hello.txt", response.headers["Content-Disposition"]
    assert_equal "text/plain", response.headers["Content-Type"]
    assert_equal "Hello world!", response.body
  end

  test "showing blob range" do
    blob = create_blob
    get blob.url, headers: { "Range" => "bytes=5-9" }
    assert_response :partial_content
    assert_equal "attachment; filename=\"hello.txt\"; filename*=UTF-8''hello.txt", response.headers["Content-Disposition"]
    assert_equal "text/plain", response.headers["Content-Type"]
    assert_equal " worl", response.body
  end

  test "showing blob with invalid range" do
    blob = create_blob
    get blob.url, headers: { "Range" => "bytes=1000-1000" }
    assert_response :range_not_satisfiable
  end

  test "showing blob that does not exist" do
    blob = create_blob
    blob.delete

    get blob.url
    assert_response :not_found
  end

  test "showing blob with invalid key" do
    get rails_disk_service_url(encoded_key: "Invalid key", filename: "hello.txt")
    assert_response :not_found
  end

  test "showing public blob" do
    blob = create_blob(content_type: "image/jpeg", service_name: :solid_storage_public)

    get blob.url
    assert_response :ok
    assert_equal "image/jpeg", response.headers["Content-Type"]
    assert_equal "Hello world!", response.body
  end

  test "showing public blob variant" do
    blob = create_file_blob(service_name: :solid_storage_public).variant(resize_to_limit: [ 100, 100 ]).processed

    get blob.url
    assert_response :ok
    assert_equal "image/jpeg", response.headers["Content-Type"]
  end

  test "directly uploading blob with integrity" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: OpenSSL::Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }
    assert_response :no_content
    assert_equal data, blob.download
  end

  test "directly uploading blob without integrity" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: OpenSSL::Digest::MD5.base64digest("bad data")

    put blob.service_url_for_direct_upload, params: data
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "directly uploading blob with mismatched content type" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size, checksum: OpenSSL::Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "application/octet-stream" }
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "directly uploading blob with different but equivalent content type" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload(
      byte_size: data.size, checksum: OpenSSL::Digest::MD5.base64digest(data), content_type: "application/x-gzip")

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "application/x-gzip" }
    assert_response :no_content
    assert_equal data, blob.download
  end

  test "directly uploading blob with mismatched content length" do
    data = "Something else entirely!"
    blob = create_blob_before_direct_upload byte_size: data.size - 1, checksum: OpenSSL::Digest::MD5.base64digest(data)

    put blob.service_url_for_direct_upload, params: data, headers: { "Content-Type" => "text/plain" }
    assert_response :unprocessable_entity
    assert_not blob.service.exist?(blob.key)
  end

  test "directly uploading blob with invalid token" do
    put update_rails_disk_service_url(encoded_token: "invalid"),
      params: "Something else entirely!", headers: { "Content-Type" => "text/plain" }
    assert_response :not_found
  end

  private

  def create_blob(key: nil, data: "Hello world!", filename: "hello.txt", content_type: "text/plain", identify: true, record: nil, service_name: :solid_storage)
    ActiveStorage::Blob.create_and_upload! key:, io: StringIO.new(data), filename:, content_type:, identify:, service_name:, record:
  end

  def create_file_blob(key: nil, filename: "racecar.jpg", fixture: filename, content_type: "image/jpeg", identify: true, metadata: nil, service_name: :solid_storage, record: nil)
    ActiveStorage::Blob.create_and_upload! io: file_fixture(fixture).open, filename:, content_type:, identify:, metadata:, service_name:, record:
  end

  def create_blob_before_direct_upload(key: nil, filename: "hello.txt", byte_size:, checksum:, content_type: "text/plain", record: nil)
    ActiveStorage::Blob.create_before_direct_upload! key: key, filename: filename, byte_size: byte_size, checksum: checksum, content_type: content_type, record: record
  end
end
