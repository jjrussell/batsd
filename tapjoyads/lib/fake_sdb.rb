class FakeSdb
  @@fake_sdb_data ||= {}

  def put_attributes(domain, key, attrs_to_put, attrs_to_replace, expected_attr)
    data_key = "#{domain}.#{key}"

    existing_attrs = @@fake_sdb_data[data_key] || {}
    @@fake_sdb_data[data_key] = existing_attrs.merge(attrs_to_put)
  end

  def get_attributes(domain, key, something, consistent)
    data_key = "#{domain}.#{key}"

    attributes = @@fake_sdb_data[data_key] || {}
    { :attributes => attributes }
  end

  def delete_attributes(domain, key, attrs_to_delete, expected_attr)
    data_key = "#{domain}.#{key}"

    attributes = @@fake_sdb_data[data_key] || {}
    attrs_to_delete.each do |attr, value|
      attributes.delete(attr)
    end

    @@fake_sdb_data[data_key] = attributes
  end
end
