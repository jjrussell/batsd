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

    if attrs_to_delete.empty?
      @@fake_sdb_data.delete(key)
    else
      attributes = @@fake_sdb_data[data_key] || {}
      attrs_to_delete.each do |attr, value|
        attributes.delete(attr)
      end
      @@fake_sdb_data[data_key] = attributes
    end

  end

  def select(query, next_token, consistent)
    options = parse_query(query)
    domain = options.delete(:from)
    results = @@fake_sdb_data.reject { |k, v|
      k !~ /#{domain}/
    }
    final_results = {}

    options[:where].each do |element|
      if element.is_a? Array
        element = element.first if element.first.is_a? Array
        new_results = results.reject do |key, record|
          record[element.first] && record[element.first].first != element.last
        end
        final_results.merge!(new_results)
      end
    end

    case options[:select].first
    when '*'
      array_results = final_results.map { |k, v| { k => v } }
      { :items => array_results }
    when 'count(*)'
      { :items => [ { 'Domain' => { 'Count' => [ final_results.count ] } } ] }
    end
  end

  private

  def parse_query(query)
    query_array = query.split
    options = {}
    while word = query_array.shift do
      case word
      when /SELECT/i
        options[:select] ||= []
        options_array = options[:select]
      when /FROM/i
        options[:from] ||= []
        options_array = options[:from]
      when /WHERE/i
        options[:where] ||= []
        options_array = []
        options[:where] << [ options_array ]
      when /OR/i
        options_array = []
        options[:where] << :or << options_array
      else
        options_array << word.gsub('`', '').gsub("'", '')
      end
    end
    options
  end
end
