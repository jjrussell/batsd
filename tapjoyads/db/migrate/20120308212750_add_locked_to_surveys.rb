class AddLockedToSurveys < ActiveRecord::Migration
  def self.up
    add_column :survey_offers, :locked, :boolean, :null => false, :default => false
  end

  def self.down
    remove_column :survey_offers, :locked
  end
end
