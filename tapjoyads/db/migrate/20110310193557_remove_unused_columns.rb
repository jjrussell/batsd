class RemoveUnusedColumns < ActiveRecord::Migration
  def self.up
    remove_column :apps, :first_pinged_at
    remove_column :apps, :submitted_to_store_at
    remove_column :apps, :approved_by_store_at
    remove_column :apps, :approved_by_tapjoy_at
    remove_column :apps, :enabled_at

    remove_column :offers, :description
    remove_column :offers, :instructions
    remove_column :offers, :time_delay
    remove_column :offers, :credit_card_required
    remove_column :offers, :last_balance_alert_time
  end

  def self.down
    add_column :apps, :first_pinged_at, :datetime
    add_column :apps, :submitted_to_store_at, :datetime
    add_column :apps, :approved_by_store_at, :datetime
    add_column :apps, :approved_by_tapjoy_at, :datetime
    add_column :apps, :enabled_at, :datetime

    add_column :offers, :description, :text
    add_column :offers, :instructions, :text
    add_column :offers, :time_delay, :string
    add_column :offers, :credit_card_required, :boolean, :default => false, :null => false
    add_column :offers, :last_balance_alert_time, :datetime
  end
end
