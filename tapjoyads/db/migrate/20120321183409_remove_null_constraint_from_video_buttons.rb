class RemoveNullConstraintFromVideoButtons < ActiveRecord::Migration
  def self.up
    change_column :video_buttons, :url, :string, :null => true
  end

  def self.down
    change_column :video_buttons, :url, :string, :null => false
  end
end
