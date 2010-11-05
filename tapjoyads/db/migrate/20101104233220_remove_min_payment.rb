class RemoveMinPayment < ActiveRecord::Migration
  def self.up
    remove_column :offers, :min_payment
  end

  def self.down
    add_column :offers, :min_payment, :integer
  end
end
