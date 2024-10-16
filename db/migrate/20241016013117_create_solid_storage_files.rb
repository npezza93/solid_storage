class CreateSolidStorageFiles < ActiveRecord::Migration[7.2]
  def change
    create_table :solid_storage_files do |t|
      t.binary :data, limit: 536870912
      t.string :key
      t.index :key

      t.timestamps
    end
  end
end
