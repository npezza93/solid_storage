ActiveRecord::Schema[7.1].define(version: 1) do
  create_table "solid_storage_files", force: :cascade do |t|
    t.binary "data", limit: 536870912
    t.string "key"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_storage_files_on_key"
  end
end
