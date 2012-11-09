class CreateExperiments < ActiveRecord::Migration
  def self.up
    # Experiments
    create_table :experiments, :id => false do |t|
      t.column    :id, 'char(36) binary', :null => false
      t.column    :owner_id, 'char(36) binary', :null => false
      t.string    :name, :null => false
      t.text      :description, :null => false

      # Dates
      t.datetime  :started_at
      t.datetime  :ended_at
      t.datetime  :due_at

      # % of users in the test group
      t.float     :ratio, :null => false

      # UDID list to force into test group (serialized)
      t.string    :udid_whitelist

      # Number of devices required for test population
      t.integer   :population_size, :null => false

      # Type of bucket to use for this experiment
      t.string    :bucket_type, :null => false

      # String of random characters
      t.string    :randomizer, :null => false

      # Metadata we want to keep but not query on (serialized)
      t.text      :metadata

      t.timestamps
    end

    add_index :experiments, :id, :unique => true

    # ExperimentBuckets
    create_table :experiment_buckets, :id => false do |t|
      t.column     :id, 'char(36) binary', :null => false
      t.column     :experiment_id, 'char(36) binary'
      t.string     :bucket_type

      t.timestamps
    end

    add_index :experiment_buckets, :id, :unique => true
    add_index :experiment_buckets, :experiment_id

    # apps can belong to an experiment now
    add_column :apps, :experiment_id, 'char(36) binary'
  end

  def self.down
    drop_table :experiments
    drop_table :experiment_buckets
    remove_column :apps, :experiment_id

    # No, we can't use ExperimentBucket::LOOKUP_KEY because that model
    # is not required to exist in order to run this migration
    $perma_redis.del('experiments:buckets_by_index')
    $perma_redis.del('experiments:hash_offset')
    $perma_redis.del('experiments:ids_by_name')
  end
end
