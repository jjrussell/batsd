class ChangePayoutStatusDefault < ActiveRecord::Migration
  def self.up
    change_column_default :payouts, :status, 1
  end

  def self.down
    # no down
  end
end
