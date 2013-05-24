class AddDisabledPartnersToCurrencies < ActiveRecord::Migration
  def self.up
    add_column :currencies, :disabled_partners, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :currencies, :disabled_partners
  end
end
