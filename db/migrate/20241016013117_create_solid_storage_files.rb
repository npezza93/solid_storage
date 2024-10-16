class CreateSolidStorageFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :solid_storage_files do |t|
      t.blob :data
      t.string :key
      t.index :key

      t.timestamps
    end
  end
end
