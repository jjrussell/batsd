class AddDisabledAtToCurrencySales < ActiveRecord::Migration
  def self.up
    add_column :currency_sales, :disabled_at, :timestamp
  end

  def self.down
    remove_column :currency_sales, :disabled_at
  end
end
