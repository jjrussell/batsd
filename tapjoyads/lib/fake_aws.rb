class RightAws::SdbInterface
  def put_attributes(domain, key, attrs_to_put, attrs_to_replace, expected_attr)
    existing_attrs = Mc.get("fake_sdb.#{key}") || {}
    Mc.put("fake_sdb.#{key}", existing_attrs.merge(attrs_to_put))
  end

  def get_attributes(domain_name, key, something, consistent)
    attributes = Mc.get("fake_sdb.#{key}") || {}
    { :attributes => attributes }
  end

  def delete_attributes(domain_name, key, attrs_to_delete, expected_attr)
    attributes = Mc.get("fake_sdb.#{key}") || {}
    attrs_to_delete.each do |attr, value|
      attributes.delete(attr)
    end
    Mc.put("fake_sdb.#{key}", attributes)
  end
end

class S3
  def self.bucket(bucket_name)
    FakeBucket.new(bucket_name)
  end
end

class FakeBucket
  def initialize(bucket_name)
    @bucket_name = bucket_name
  end

  def objects
    FakeObjects.new(@bucket_name)
  end
end

class FakeObjects
  def initialize(bucket_name)
    @bucket_name = bucket_name
  end

  def [](key)
    FakeObject.new(key)
  end
end

class FakeObject
  def initialize(key)
    @key = key
  end

  def write(data)
    Mc.put("fake_object.#{@key}", data[:data])
  end
end
