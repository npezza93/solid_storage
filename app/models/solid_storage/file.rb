class SolidStorage::File < SolidStorage::Record
  belongs_to :blob, class_name: "ActiveStorage::Blob",
                    primary_key: :key, foreign_key: :key
end
