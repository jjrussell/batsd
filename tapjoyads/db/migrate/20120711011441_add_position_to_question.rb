class AddPositionToQuestion < ActiveRecord::Migration
  def self.up
    add_column :survey_questions, :position, :integer, :null => false
  end

  def self.down
    remove_column :survey_questions, :position
  end
end
