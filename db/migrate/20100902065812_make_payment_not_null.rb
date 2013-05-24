class MakePaymentNotNull < ActiveRecord::Migration
  def self.up
    change_column :offers, :payment, :integer, :null => false, :default => 0
  end

  def self.down
    # no down
  end
end
