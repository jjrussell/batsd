class AddMaxDeductionPercentageToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :max_deduction_percentage, :decimal, :precision => 8, :scale => 6, :default => 1, :null => false
  end

  def self.down
    remove_column :partners, :max_deduction_percentage
  end
end
