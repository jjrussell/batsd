class AddMetroCodesToOffers < ActiveRecord::Migration
  def self.up
    add_column :offers, :dma_codes, :text
  end

  def self.down
    remove_column :offers, :dma_codes
  end
end
