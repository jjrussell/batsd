class AddLiveDateToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :live_date, :datetime
  end

  def self.down
    remove_column :partners, :live_date
  end
end
