class AddNoteToOrders < ActiveRecord::Migration
  def self.up
    add_column :orders, :note, :text
  end

  def self.down
    remove_column :order, :note
  end
end
