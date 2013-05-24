class ChangeCurrenciesExternalPublishers < ActiveRecord::Migration
  def self.up
    rename_column :currencies, :potential_external_publisher, :udid_for_user_id
  end

  def self.down
    ename_column :currencies, :udid_for_user_id, :potential_external_publisher
  end
end
