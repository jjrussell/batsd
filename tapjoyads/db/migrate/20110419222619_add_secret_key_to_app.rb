class AddSecretKeyToApp < ActiveRecord::Migration
  def self.up
    add_column :apps, :secret_key, :string, :null => false
  end

  def self.down
    remove_column :apps, :secret_key
  end
end
