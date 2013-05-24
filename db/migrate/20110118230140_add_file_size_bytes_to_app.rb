class AddFileSizeBytesToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :file_size_bytes, :integer
    add_column :apps, :supported_devices, :string
  end

  def self.down
    remove_column :apps, :file_size_bytes
    remove_column :apps, :supported_devices
  end
end
