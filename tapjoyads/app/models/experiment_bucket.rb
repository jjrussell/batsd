class ExperimentBucket < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable
  belongs_to :experiment

  validates :bucket_type, :inclusion => {:in => %w{interface optimization}}

  # NOTE: Changing the value of this constant will break
  # the down method of the CreateExperiments migration
  # (so go change it there too and leave this comment)
  LOOKUP_KEY = 'experiments:buckets_by_index'
  OFFSET_KEY = 'experiments:hash_offset'

  # We need to be able to access buckets by their index (creation order)
  # because I *still* can't get modulo division to return a UDID
  def self.id_for_index(i)
    $perma_redis.hget(LOOKUP_KEY, i)
  end

  def self.for_index(i)
    find_in_cache(id_for_index(i))
  end

  def self.count_from_cache
    $perma_redis.hlen(LOOKUP_KEY)
  end

  def self.hash_offset
    $perma_redis.get(OFFSET_KEY).to_i # nil.to_i => 0
  end

  # Assign experiment buckets to each device
  def self.rehash_population(opts = {}, &block)
    buckets    = opts.delete(:buckets) { 10_000 } # number of buckets to hash into
    offset     = opts.delete(:offset) { 0 } # we use a subset of the UDID digest to hash
    limit      = opts.delete(:limit) { nil }
    alternate  = opts.delete(:alternate) { true }

    # offset can be <= 58, else grabbing 6 chars runs past the end of our 64-char SHA1 hashes
    # if we need more, we can add some (constant) garbage to the end of udids pre-hashing
    raise ArgumentError.new("Offset too large") if offset > 58
    $perma_redis.set(OFFSET_KEY, offset)

    # Wipe all existing buckets and create new ones
    self.destroy_all
    $perma_redis.del(LOOKUP_KEY)
    bucket_type = 'optimization'
    buckets = buckets.times.collect do |index|
      self.create(:bucket_type => bucket_type)
      bucket_type = (bucket_type == 'optimization') ? 'interface' : 'optimization' if alternate
    end

    ExperimentBucket.order('id asc').all.each_with_index do |bucket, i|
      $perma_redis.hset(LOOKUP_KEY, i, bucket.id)
    end

    # Recalculate average bucket size on the offchance someone is using us from the console (or RSpec)
    average_size!
  end

  # Approximate count of the devices assigned to this bucket
  def size
    ExperimentBucket.average_size
  end

  def self.average_size
    @average_size ||= average_size!
  end

  def self.average_size!
    @average_size = (Device.cached_count / count_from_cache) rescue 0
  end
end
