# TODO: Missing functionality
# Deleting multiple values
class FakeSdb

  def put_attributes(domain, key, attrs_to_put, attrs_to_replace = {}, expected_attrs = {})
    existing_attrs = fake_sdb_data(domain)[key] || {}
    unless expected_attrs.empty?
      raise Simpledb::MultipleExistsConditionsError if expected_attrs.size > 1
      expected_key = expected_attrs.first.first
      expected_value = expected_attrs.first.last

      #  This seems to match behavior in RightAWS's SdbInterface,  if not Amazon's developer guide at:
      #  http://docs.amazonwebservices.com/AmazonSimpleDB/latest/DeveloperGuide/SDB_API_PutAttributes.html
      #  RightAWS code seems to reject expected_attrs  that do not also exist in attrs_to_put
      #  Probably worth investigating at some point.
      existing = get_attributes(domain, key)[:attributes]

      if attrs_to_put.keys.include?(expected_key)
        raise Simpledb::ExpectedAttributeError if expected_value.nil? && existing[expected_key].present?
        raise Simpledb::ExpectedAttributeError if expected_value != existing[expected_key].try(:first)
      end
    end
    fake_sdb_data(domain)[key] = existing_attrs.merge(attrs_to_put.dup)
  end

  def get_attributes(domain, key, attribute_name=nil, consistent=false)
    attributes = fake_sdb_data(domain)[key] || {}
    { :attributes => attributes.dup }
  end

  def delete_attributes(domain, key, attrs_to_delete = {}, expected_attrs = {})
    if attrs_to_delete.empty?
      fake_sdb_data(domain).delete(key)
    else
      attributes = fake_sdb_data(domain)[key] || {}
      attrs_to_delete.each do |attr, value|
        attributes.delete(attr)
      end
      fake_sdb_data(domain)[key] = attributes
    end

  end

  def select(query, next_token, consistent)
    options = parse_query(query)
    domain = options.delete(:from).first
    results = fake_sdb_data(domain)
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
      { :items => array_results.dup }
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
      when /^SELECT$/i
        options[:select] ||= []
        options_array = options[:select]
      when /^FROM$/i
        options[:from] ||= []
        options_array = options[:from]
      when /^WHERE$/i
        options[:where] ||= []
        options_array = []
        options[:where] << options_array
      when /^OR$/i
        options_array = []
        options[:where] << :or << options_array
      when /^LIMIT$/i
        options_array = []
        options[:limit] ||= [options_array]
      when /^ORDER BY/i
      else
        options_array << word.gsub('`', '').gsub("'", '')
      end
    end
    options
  end

  private

  def fake_sdb_data(domain)
    @fake_sdb_data ||= {}
    @fake_sdb_data[domain] ||= {}
  end
end
