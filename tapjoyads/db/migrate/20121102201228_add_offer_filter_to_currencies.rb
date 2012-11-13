class AddOfferFilterToCurrencies < ActiveRecord::Migration
  def self.up
    # sample data: "ActionOffer,App,SurveyOffer", only the specified offers will be shown on offerwall
    add_column :currencies, :offer_filter, :string, :default => nil
  end

  def self.down
    remove_column :currencies, :offer_filter
  end
end
