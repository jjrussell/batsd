class AddXPartnerPrerequisitesToAllOfferTypes < ActiveRecord::Migration
  def self.up
    add_column :action_offers, :x_partner_prerequisites, :text, :null => false, :default => ''
    add_column :action_offers, :x_partner_exclusion_prerequisites, :text, :null => false, :default => ''
    add_column :generic_offers, :x_partner_prerequisites, :text, :null => false, :default => ''
    add_column :generic_offers, :x_partner_exclusion_prerequisites, :text, :null => false, :default => ''
    add_column :video_offers, :x_partner_prerequisites, :text, :null => false, :default => ''
    add_column :video_offers, :x_partner_exclusion_prerequisites, :text, :null => false, :default => ''
    add_column :offers, :x_partner_prerequisites, :text, :null => false, :default => ''
    add_column :offers, :x_partner_exclusion_prerequisites, :text, :null => false, :default => ''
  end

  def self.down
    remove_column :action_offers, :x_partner_prerequisites
    remove_column :action_offers, :x_partner_exclusion_prerequisites
    remove_column :generic_offers, :x_partner_prerequisites
    remove_column :generic_offers, :x_partner_exclusion_prerequisites
    remove_column :video_offers, :x_partner_prerequisites
    remove_column :video_offers, :x_partner_exclusion_prerequisites
    remove_column :offers, :x_partner_prerequisites
    remove_column :offers, :x_partner_exclusion_prerequisites
  end
end
