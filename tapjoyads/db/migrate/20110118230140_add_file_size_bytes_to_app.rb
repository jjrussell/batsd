class AddFileSizeBytesToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :file_size_bytes, :integer
  end

  def self.down
    remove_column :apps, :file_size_bytes
  end
end
