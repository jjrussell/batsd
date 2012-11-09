require 'digest'

class Experiment < ActiveRecord::Base
  include UuidPrimaryKey
  acts_as_cacheable

  LOOKUP_KEY = 'experiments:ids_by_name'

  serialize :metadata, Hash

  belongs_to :owner, :class_name => 'User'

  # These two associations need to be extended to prevent duplicate assignment.
  # They are almost similar enough to DRY with some MP but not quite.
  has_many(:apps, :autosave => true) do
    def <<(app)
      app.experiment.nil? or raise AppNotAvailable
      super(app)
    end
  end

  has_many(:buckets, :class_name => 'ExperimentBucket', :autosave => true) do
    def <<(bucket)
      bucket.experiment.nil? or raise BucketNotAvailable
      super(bucket)
    end
  end

  # Ensure we have a bucket_type, randomizer, and our metadata hash is initialized
  before_validation do
    self.bucket_type = (apps.any? ? 'optimization' : 'interface') if bucket_type.blank?
    self.randomizer  = SecureRandom.base64 if randomizer.blank?

    update_metadata    unless concluded?
    true # don't abort
  end

  validates :started_at, :due_at, :ratio, :name, :description, :population_size, :randomizer, :owner, :presence => true
  validates :bucket_type, :inclusion => { :in => %w{interface optimization} }
  validates :population_size, :numericality => { :only_integer => true, :greater_than => 0}
  validates :ratio, :numericality => { :greater_than => 0, :less_than => 100 }
  validates :name, :uniqueness => true

  validate do
    # Rescuing these in case the attribute is missing, which will have been caught above
    started_at > Date.today or errors.add(:started_at, 'must not be in the past') rescue nil
    due_at > started_at or errors.add(:due_at, 'must be after start date') rescue nil

    # Are there enough free devices to create this experiment?
    if population_size && self.metadata[:bucket_ids].empty?
      self.available_buckets.map(&:size).reduce(:+) >= population_size or errors.add(:population_size, 'insufficient available devices')
    end

    if bucket_type == 'interface' && apps.any?
      errors.add(:app_ids, 'must be blank for interface experiment')
    end
  end

  # Update our lookup-by-name in Redis
  after_save { |e| $perma_redis.hset(LOOKUP_KEY, e.name, e.id) }

  # Remove ourselves from cache lookup
  before_destroy do |e|
    $perma_redis.hdel(LOOKUP_KEY, e.name)
    e.release_devices!
  end

  # Look up experiment from cache by name
  def self.[](name)
    if exp_id = $perma_redis.hget(LOOKUP_KEY, name)
      Experiment.find_in_cache(exp_id)
    else
      raise ActiveRecord::RecordNotFound.new("No experiment found in cache by name '#{name}'")
    end
  end

  def interface?
    bucket_type == 'interface'
  end

  def optimization?
    bucket_type == 'optimization'
  end

  def unscheduled?
    !started_at
  end

  def scheduled?
    started_at > Time.now
  end

  def running?
    started_at < Time.now && !ended_at
  end

  def concluded?
    started_at && ended_at
  end

  # Begin the experiment right now
  def start!
    scheduled? or raise ExperimentNotScheduled

    self.started_at = Time.now
    self.save!
  end

  # End the experiment right now (releasing devices)
  def conclude!
    running? or raise ExperimentNotRunning

    self.ended_at = Time.now
    self.release_devices!
    self.save!
  end

  # Depending on the state of the experiment, a particular set of attributes
  # are editable
  def editable_attrs
    if unscheduled? || new_record?
      [:name, :description, :started_at, :due_at, :ratio, :population_size, :app_ids]
    elsif scheduled?
      [:started_at, :due_at, :ratio]
    elsif running?
      [:due_at]
    else
      []
    end
  end

  # SLOW: number of devices reserved for this experiment.
  # This will execute a SimpleDB count on Device for each
  # assigned bucket
  def reserved_devices
    buckets.inject(0) { |devices, bucket| devices += bucket.size }
  end

  # SLOW: Loop through available buckets of the proper type, assigning
  # to this experiment until we have enough users to satisfy the population
  # requirements
  def reserve_devices!
    raise AlreadyHasBuckets if buckets.any?

    free_buckets = self.available_buckets
    raise NoAvailableBuckets unless free_buckets.any?

    reserved_buckets = []
    while reserved_buckets.inject(0) { |devices, bucket| devices += bucket.size } < population_size
      raise NoAvailableBuckets unless free_buckets.any?
      reserved_buckets << free_buckets.pop
    end

    reserved_buckets.each { |bucket| self.buckets << bucket }
    self.save!
  end

  # Iterate apps and buckets assigned to this experiment
  # and free them.
  def release_devices!
    [apps, buckets].flatten.each do |association|
      association.experiment_id = nil
      association.save
    end
  end

  def app_ids
    self.apps.collect(&:id).join(',')
  end

  def app_ids=(ids)
    self.apps.clear
    ids.split(',').each do |app_id|
      app_id.strip!
      next if app_id.blank? # allow extra commas in app_ids
      self.apps << App.find(app_id)
    end
  end

  def available_buckets
    ExperimentBucket.where(:experiment_id => nil, :bucket_type => bucket_type)
  end

  def group_for(device)
    # Is the device in this experiment?
    self.buckets.any? { |b| device.experiment_bucket_id == b.id } or return nil

    # Is the experiment running yet?
    self.running? or return 'control'

    # Hash into percentiles
    percentile = Digest::SHA1.hexdigest("#{device.key}#{self.randomizer}").hex % 100
    percentile < self.ratio ? 'test' : 'control'
  end

  def update_metadata
    self.metadata ||= {}

    self.metadata.merge!(
      :app_ids    => apps.collect(&:id),
      :bucket_ids => buckets.collect(&:id)
    )
  end

  class Error < StandardError; end
  class AlreadyHasBuckets < Error; end
  class AppNotAvailable < Error; end
  class BucketNotAvailable < Error; end
  class NoAvailableBuckets < Error; end
  class ExperimentNotRunning < Error; end
  class ExperimentNotScheduled < Error; end
end

