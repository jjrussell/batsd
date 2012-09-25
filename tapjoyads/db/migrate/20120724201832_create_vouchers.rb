class CreateVouchers < ActiveRecord::Migration
  def self.up
    create_table :vouchers, :id => false do |t|
      t.guid    :id,                            :null => false
      t.column  :click_key, 'char(36) binary',  :null => false
      t.column  :ref_id, 'char(36) binary',     :null => false
      t.column  :coupon_id, 'char(36) binary',  :null => false
      t.string  :redemption_code,               :null => false
      t.date    :acquired_at,                   :null => false
      t.date    :expires_at,                    :null => false
      t.string  :barcode_url,                   :null => false
      t.string  :email_address,                 :null => false
      t.boolean :completed, :default => false,  :null => false
      t.timestamps
    end

    add_index :vouchers, :id
  end

  def self.down
    drop_table :vouchers
  end
end
