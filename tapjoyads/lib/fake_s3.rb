class FakeS3
  def buckets
    @@fake_buckets ||= FakeBuckets.new
  end
end

class FakeBuckets
  def initialize
    @fake_buckets = {}
  end
  def [](bucket_name)
    @fake_buckets[bucket_name] ||= FakeBucket.new
  end
end

class FakeBucket
  def objects
    @fake_objects ||= FakeObjects.new
  end
end

class FakeObjects
  def [](key)
    @fake_objects ||= {}
    @fake_objects[key] ||= FakeObject.new(key)
  end

  def with_prefix(prefix)
    @fake_objects ||= {}
    @fake_objects.reject { |key, value| key !~ /#{prefix}/ }.values
  end
end

class FakeObject
  REAL_KEYS = [
    'icons/survey-blue.png',
    'display/round_mask.png',
  ]

  DATA_KEYS = [
    'most_popular.txt',
    'app_app_matrix.txt',
    'daily/udid_apps_reco.dat'
  ]

  def initialize(key)
    @key = key
    if REAL_KEYS.include? @key
      @data = File.open("#{Rails.root}/public/images/gunbros.png").read
    elsif DATA_KEYS.include? @key
      @data = File.open("#{Rails.root}/spec/data/#{@key}").read
    end
  end

  def write(data)
    @data = data
  end

  def read
    raise AWS::S3::Errors::NoSuchKey.new(nil, nil) unless @data
    @data
  end

  def exists?
    @data ? true : false
  end
end
