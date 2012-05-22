class AddSalesRepsToOffers < ActiveRecord::Migration
  def self.up
    create_table :sales_reps, :id => false do |t|
      t.guid :id, :null => false
      t.guid :sales_rep_id, :null => false
      t.guid :offer_id, :null => false
      t.datetime :start_date, :null => false
      t.datetime :end_date
    end

    add_index :sales_reps, :sales_rep_id
    add_index :sales_reps, :offer_id
  end

  def self.down
    drop_table :sales_reps
  end
end
