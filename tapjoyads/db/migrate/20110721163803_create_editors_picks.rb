class CreateEditorsPicks < ActiveRecord::Migration
  def self.up
    create_table :editors_picks, :id => false do |t|
      t.column    :id, 'char(36) binary', :null => false
      t.column    :offer_id, 'char(36) binary', :null => false
      t.integer   :display_order, :null => false, :default => 100
      t.string    :description, :null => false, :default => ''
      t.string    :internal_notes, :null => false, :default => ''
      t.timestamp :scheduled_for, :null => false
      t.timestamp :activated_at
      t.timestamp :expired_at

      t.timestamps
    end

    add_index :editors_picks, :id, :unique => true
    add_index :editors_picks, :offer_id
    add_index :editors_picks, :scheduled_for
    add_index :editors_picks, :activated_at
    add_index :editors_picks, :expired_at
  end

  def self.down
    drop_table :editors_picks
  end
end
