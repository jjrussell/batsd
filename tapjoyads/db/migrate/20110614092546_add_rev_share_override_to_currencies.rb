class AddRevShareOverrideToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :rev_share_override, :decimal, :precision => 8, :scale => 6
  end

  def self.down
    remove_column :currencies, :rev_share_override
  end
end
