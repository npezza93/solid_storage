class SolidStorage::File < SolidStorage::Record
  belongs_to :blob, class_name: "ActiveStorage::Blob",
                    primary_key: :key, foreign_key: :key, optional: true

  def tempfile
    @tempfile ||= Tempfile.new.tap do |file|
      file.write(data)
    end
  end

  def io
    StringIO.new(data)
  end
end
