class CreateCoupons < ActiveRecord::Migration
  def self.up
    create_table :coupons, :id => false do |t|
      t.guid      :id,                                           :null => false
      t.column    :provider_id, 'char(36) binary',               :null => false
      t.column    :partner_id, 'char(36) binary',                :null => false
      t.column    :prerequisite_offer_id, 'char(36) binary'
      t.string    :name,                                         :null => false
      t.text      :description
      t.text      :fine_print
      t.string    :illustration_url
      t.date      :start_date
      t.date      :end_date
      t.string    :discount_type
      t.string    :discount_value
      t.string    :advertiser_id
      t.string    :advertiser_name
      t.string    :advertiser_url
      t.text      :advertiser_description
      t.string    :vouchers_expire_type
      t.date      :vouchers_expire_date
      t.string    :vouchers_expire_time_unit
      t.integer   :vouchers_expire_time_amount
      t.string    :url
      t.text      :instructions
      t.integer   :price,                                                                 :default => 0
      t.boolean   :hidden,                                       :null => false,          :default => false
      t.timestamps
    end

    add_index :coupons, :id
    add_index :coupons, :partner_id
    add_index :coupons, :prerequisite_offer_id
    add_index :coupons, :provider_id
  end

  def self.down
    drop_table :coupons
  end
end
