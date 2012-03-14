class FixApprovalsTable < ActiveRecord::Migration
  def self.up
    remove_column :approvals, :object

    add_column    :approvals, :object,    :text, :limit => 16777216
    add_column    :approvals, :original,  :text, :limit => 16777216
  end

  def self.down
    remove_column :approvals, :original
    remove_column :approvals, :object

    add_column    :approvals, :object, :text
  end
end
