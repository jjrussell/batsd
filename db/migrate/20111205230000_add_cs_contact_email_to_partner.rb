class AddCsContactEmailToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :cs_contact_email, :string
  end

  def self.down
    remove_column :partners, :cs_contact_email
  end
end
