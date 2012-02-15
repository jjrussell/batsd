class DeleteHasVirtualGoods < ActiveRecord::Migration
  def self.up
    remove_column :currencies, :has_virtual_goods
  end

  def self.down
    add_column :currencies, :has_virtual_goods, :null => false, :default => false
  end
end
