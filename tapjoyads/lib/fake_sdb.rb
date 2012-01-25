class FakeSdb
  @@fake_sdb_data ||= {}

  def put_attributes(domain, key, attrs_to_put, attrs_to_replace = {}, expected_attrs = {})
    data_key = "#{domain}.#{key}"

    existing_attrs = @@fake_sdb_data[data_key] || {}
    expected_attrs.each do |key, value|
      if key == 'version'
        current_version = existing_attrs[key]
        if current_version && current_version.first.to_i != value.to_i + 1
          raise Simpledb::ExpectedAttributeError
        end
      elsif existing_attrs[key] != value
        raise Simpledb::ExpectedAttributeError
      end
    end
    @@fake_sdb_data[data_key] = existing_attrs.merge(attrs_to_put)
  end

  def get_attributes(domain, key, something, consistent)
    data_key = "#{domain}.#{key}"

    attributes = @@fake_sdb_data[data_key] || {}
    { :attributes => attributes }
  end

  def delete_attributes(domain, key, attrs_to_delete = {}, expected_attrs = {})
    data_key = "#{domain}.#{key}"

    attributes = @@fake_sdb_data[data_key] || {}
    attrs_to_delete.each do |attr, value|
      attributes.delete(attr)
    end

    @@fake_sdb_data[data_key] = attributes
  end
end
