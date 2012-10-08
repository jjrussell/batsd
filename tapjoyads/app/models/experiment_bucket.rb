class ExperimentBucket < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  belongs_to :experiment

  validates :bucket_type, :inclusion => {:in => %w{interface optimization}}

  # NOTE: Changing the value of this constant will break
  # the down method of the CreateExperiments migration
  # (so go change it there too and leave this comment)
  REDIS_HASH_KEY = 'experiments:buckets_by_index'


  # We need to be able to access buckets by their index (creation order)
  # because I *still* can't get modulo division to return a UDID
  def self.id_for_index(i)
    $redis.hget(REDIS_HASH_KEY, i)
  end

  def self.for_index(i)
    find_in_cache(id_for_index(i))
  end

  def self.count_from_cache
    $redis.hlen(REDIS_HASH_KEY)
  end

  # Assign experiment buckets to each device
  def self.rehash_population(opts = {}, &block)
    buckets    = opts.delete(:buckets) { 1000 } # number of buckets to hash into
    offset     = opts.delete(:offset) { 0 } # we use a subset of the UDID digest to hash
    limit      = opts.delete(:limit) { nil }
    chunk_size = opts.delete(:chunk_size) { 10000 }
    alternate  = opts.delete(:alternate) { true }

    # offset can be <= 58, else grabbing 6 chars runs past the end of our 64-char SHA1 hashes
    # if we need more, we can add some (constant) garbage to the end of udids pre-hashing
    raise ArgumentError.new("Offset too large") if offset > 58
    $redis.set('experiments:hash_offset', offset)

    # Wipe all existing buckets and create new ones
    self.destroy_all
    $redis.del(REDIS_HASH_KEY)
    bucket_type = 'optimization'
    buckets = buckets.times.collect do |index|
      self.create(:bucket_type => bucket_type)
      bucket_type = (bucket_type == 'optimization') ? 'interface' : 'optimization' if alternate
    end

    ExperimentBucket.order('id asc').all.each_with_index do |bucket, i|
      $redis.hset(REDIS_HASH_KEY, i, bucket.id)
    end

    return if limit == 0 # if maybe you just wanted to create some buckets

    # Assign a bucket to each device
    total = 0
    Device.select_all do |device|
      device.assign_experiment_bucket(offset)
      device.save
      (total += 1) == limit and break
      block.call(total) if block.is_a?(Proc) && total % chunk_size == 0
    end
  end

  # Array of devices assigned to this bucket
  def devices
    Device.select_all(condition)
  end

  # Count of the devices assigned to this bucket
  def size
    Device.count(condition)
  end

private
  def condition
    {:where => %{experiment_bucket_id = "#{self.id}"} }
  end
end
