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

  def select(query, next_token = nil, consistent = nil, &block)
    options = parse_query(query)
    domain = options.delete(:from).first.gsub(/[`"']/, '') # strip quotes
    records = fake_sdb_data(domain).dup

    if options[:where]
      # ruby 1.9 has Hash#keep_if, so let's pretend we doo tooo
      proc = keep_if_proc(options[:where])
      records.delete_if { |key, record| !proc.call(key, record) }
    end

    if block.is_a?(Proc)
      # Yield each record
      records.each do |key, record|
        block.call(record)
      end
    end

    case options[:select].first
    when '*'
      # this dup is necessary so changing values on the returned
      # items doesn't change values in the 'database'
      array_results = records.map { |k, v| { k.dup => v.dup } }

      if options[:order]
        options[:order].delete_if { |token| token.downcase == 'by' }
        column = options[:order].first.downcase
        order = options[:order].second.downcase || 'asc'

        array_results.sort! do |a, b|
          # a and b are one element hashes like key => record_hash
          a = a.values.first[column]
          b = b.values.first[column]

          order == 'asc' ? a <=> b : b <=> a
        end
      end

      if options[:limit]
        limit = options[:limit].first.to_i
        array_results = array_results.first(limit)
      end

      { :items => array_results }
    when 'count(*)'
      { :items => [ { 'Domain' => { 'Count' => [ records.count ] } } ] }
    end
  end

  private
  def parse_query(query)
    query = preprocess_query(query)
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
        options_array = options[:where]
      when /^LIMIT$/i
        options[:limit] ||= []
        options_array = options[:limit]
      when /^ORDER/i
        options[:order] ||= []
        options_array = options[:order]
      else
        options_array << word
      end
    end

    options[:where] = parse_where(options[:where]) if options[:where]
    options
  end

  # build an array like
  # [[column, operator, string], :and, [string, operator, column]]
  # or recursively like
  # [[condition, :and, condition], :or, [some more conditions]]
  def parse_where(tokens)
    conditions = []
    current_condition = []

    while token = tokens.shift
      if token.starts_with?('(')
        # all the tokens until the closing paren go into an array and recurse
        group = [token[1..-1]] # strip leading paren
        group << tokens.shift until tokens.first.ends_with?(')')
        group << tokens.shift[0..-2] # strip trailing paren

        conditions << parse_where(group)
      elsif %w{` ' "}.any? { |quote| token.starts_with?(quote) && !token.ends_with?(quote) }
        # thie
        quote = token[0..0]
        str = token
        str << (' ' + tokens.shift) until str.ends_with(quote)

        str.gsub!(quote, '') # strip quote

        # go round again with this whole string as a token
        tokens.unshift(str)
      elsif [/>/i, /</i, />=/i, /<=/i, /=/i].any? { |op| op.match(token) }
        # symbolize the sql operator so we can use it as a method later
        current_condition << (token == '=' ? :== : token.to_sym)
      elsif [/and/i, /or/i].any? { |op| op.match(token) }
        # this condition is finished, so let's add it
        conditions << current_condition unless current_condition.empty?

        # and the logical operator
        conditions << token.downcase.to_sym

        # and refresh current_condition
        current_condition = []
      else
        current_condition << token.gsub(/[`"']/, '') # strip quotes from strings
      end
    end

    # we may have one condition left in current_condition
    conditions << current_condition unless current_condition.empty?
    conditions
  end

  # returns a proc that will compare a conditions array returned by parse_where
  # to a record from the "database"
  def keep_if_proc(conditions)
    # split into groups on OR
    groups = []
    while conditions.include?(:or)
      groups << []
      groups.last << conditions.shift while conditions.first != :or
      conditions.shift # the :or
    end

    # the remaining (or only, if there was no :or) group
    groups << conditions unless conditions.empty?

    Proc.new do |key, record|
      groups.any? do |conditions| # any OR'd group is good enough
        conditions.all? do |condition| # but these conditions are AND'd
          if condition == :and
            # these don't mean anything anymore
            true
          elsif condition[0].is_a?(Array)
            # parentheses group
            keep_if_proc([condition[0]]).call(key, record)
          else
            # condition is [column, operator (symbol), value]
            real_value  = condition[0].match(/^itemname/i) ? key : record[condition[0]]
            operator    = condition[1]
            test_value  = condition[2]
            negate      = false

            # != isn't a real method
            if operator == :'!='
              operator = :==
              negate   = true
            end

            # values can be one element arrays...
            real_value = real_value.first if real_value.is_a?(Array)

            # compare test value to real value, with special nil handling
            bool = if real_value.nil?
              # TODO this is just ridiculous (but kinda cool)
              negate = false unless test_value == ':nil'
              negate || test_value == ':nil'
            else
              # convert test value to appropriate type if needed
              if real_value.is_a?(Fixnum)
                test_value = test_value.to_i
              elsif real_value.is_a?(Float)
                test_value = test_value.to_f
              end

              # compare
              real_value.send(operator, test_value)
            end

            # negate if necessary
            negate ? !bool : bool
          end
        end
      end
    end
  end

  # Convert 'difficult' things to 'easy' things before query parsing
  def preprocess_query(query)
    query.tap do |query|
      # TODO allow strings with value ':nil'
      query.gsub!(/is not null/i, '!= :nil')
      query.gsub!(/is null/i, '= :nil')
      query.gsub!(/is not/i, '!=')
      query.gsub!(/is/i, '=')
    end
  end

  def fake_sdb_data(domain)
    @fake_sdb_data ||= {}
    @fake_sdb_data[domain] ||= {}
  end
end
