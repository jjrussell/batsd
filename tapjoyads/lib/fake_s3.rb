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
end

class FakeObject
  REAL_KEYS = [
    'icons/checkbox.jpg',
    'display/round_mask.png',
  ]

  def initialize(key)
    @key = key
    if REAL_KEYS.include? @key
      @data = File.open("#{RAILS_ROOT}/public/images/gunbros.png").read
    end
  end

  def write(data)
    @data = data
  end

  def read
    @data
  end

  def exists?
    @data ? true : false
  end
end
