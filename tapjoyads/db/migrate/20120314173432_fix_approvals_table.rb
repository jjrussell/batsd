class FixApprovalsTable < ActiveRecord::Migration
  def self.up
    change_table :approvals do |t|
      t.text     :object,    :limit => 16777216
      t.text     :original,  :limit => 16777216
    end
  end

  def self.down
    change_table :approvals do |t|
      t.text     :object
    end

    remove_column :approvals, :original
  end
end
