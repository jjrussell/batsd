class AddFreshbooksFieldsToPartners < ActiveRecord::Migration
  def self.up
    add_column :partners, :billing_email, :string
    add_column :partners, :freshbooks_client_id, :integer
  end

  def self.down
    remove_column :partners, :billing_email
    remove_column :partners, :freshbooks_client_id
  end
end
