class CreateBrands < ActiveRecord::Migration
  def self.up
    create_table :brands, :id => false do |t|
      t.guid :id, :null=> false, :length => 36
      t.string :name

      t.timestamps
    end
    create_table :brand_offer_mappings, :id => false, :force => true do |t|
      t.column :id, 'char(36) binary', :null => false
      t.column :offer_id, 'char(36) binary', :null => false
      t.column :brand_id, 'char(36) binary', :null => false
    end
  end

  def self.down
    drop_table :brand_offer_mappings
    drop_table :brands
  end
end
