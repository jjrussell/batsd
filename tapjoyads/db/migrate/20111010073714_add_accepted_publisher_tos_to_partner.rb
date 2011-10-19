class AddAcceptedPublisherTosToPartner < ActiveRecord::Migration
  def self.up
    add_column :partners, :accepted_publisher_tos, :boolean
  end

  def self.down
    remove_column :partners, :accepted_publisher_tos
  end
end
