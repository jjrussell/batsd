class AddStateToCurrency < ActiveRecord::Migration
  def self.up
    add_column :currencies, :state, :integer
  end

  def self.down
    remove_column :currencies, :state
  end
end
