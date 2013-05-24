class FreshBooks
  def self.new_connection
    connection = Net::HTTP.new(FRESHBOOKS_API_URL, 443)
    connection.use_ssl = true
    connection.verify_mode = OpenSSL::SSL::VERIFY_NONE
    connection.start
  end

  def self.post_request(request)
    begin
      response = new_connection.request(request)
    rescue Exception => e
      delay ||= 0.1
      raise e if delay > 2
      Rails.logger.info("post failed, trying again after #{delay} seconds")
      sleep(delay)
      delay *= 2
      retry
    end
    check_for_errors(response)
  end

  def self.create_request(options = {})
    method = options.delete(:method) { 'client.list' }
    request = REXML::Element.new('request')
    request.attributes['method'] = method
    doc = REXML::Document.new('<?xml version="1.0" encoding="utf-8"?>')
    doc.add_element(options_to_xml!(options, request))
    request = Net::HTTP::Post.new('/api/2.1/xml-in')
    request.basic_auth FRESHBOOKS_AUTH_TOKEN, 'X'
    request.body = doc.to_s
    request.content_type = 'application/xml'
    request
  end

  def self.get_client_id(email)
    client = client_list(:email => email).first
    client ? client[:client_id] : nil
  end

  def self.client_list(options = {})
    options[:method] = 'client.list'
    options[:per_page] = 100
    page = 1
    pages = 1
    clients = []
    while page <= pages
      options[:page] = page
      response = post_request(create_request(options))
      page += 1
      pages = REXML::XPath.first(response, 'response/clients').attribute('pages').value.to_i
      REXML::XPath.each(response, 'response/clients/client') do |xml|
        clients << Hash.from_xml(xml.to_s)['client'].symbolize_keys!
      end
    end
    clients
  end

  def self.update_client(options = {})
    options[:method] = 'client.update'
    post_request(create_request(options))
    true
  end

  def self.create_client(options = {})
    options[:method] = 'client.create'
    response = post_request(create_request(options))
    REXML::XPath.first(response, 'response/client_id').text.to_i
  end

  def self.update_invoice(options = {})
    options[:method] = 'invoice.update'
    post_request(create_request(options))
    true
  end

  def self.create_invoice(options = {})
    options[:method] = 'invoice.create'
    response = post_request(create_request(options))
    REXML::XPath.first(response, 'response/invoice_id').text.to_i
  end

  def self.send_invoice(invoice_id)
    options = {
      :invoice_id => invoice_id,
      :method => 'invoice.sendByEmail',
    }
    response = post_request(create_request(options))
  end

  def self.client_emails_and_ids
    email_hash = {}
    client_list.each do |client|
      email_hash[client[:email]] ||= []
      email_hash[client[:email]] << client[:client_id]
    end
    email_hash
  end

  def self.options_to_xml!(options = {}, parent = nil)
    parent ||= REXML::Element.new('request')
    options.each do |key, value|
      element = REXML::Element.new(key.to_s)
      if value.is_a?(Hash)
        options_to_xml!(value, element)
      elsif value.is_a?(Array)
        value.each do |item|
          sub_element = REXML::Element.new(key.to_s.singularize)
          options_to_xml!(item, sub_element)
          element.elements << sub_element
        end
      else
        element.text = value.to_s
      end
      parent.elements << element
    end
    parent
  end

  def self.check_for_errors(result)
    response = REXML::Document.new(result.body)
    error = REXML::XPath.first(response, 'response/error')
    raise error.text if error
    return response if result.kind_of?(Net::HTTPSuccess)

    case result
    when Net::HTTPRedirection
      if result["location"] =~ /loginSearch/
        raise UnknownSystemError.new("Account does not exist")
      elsif result["location"] =~ /deactivated/
        raise AccountDeactivatedError.new("Account is deactivated")
      end
    when Net::HTTPUnauthorized
      raise AuthenticationError.new("Invalid API key.")
    when Net::HTTPBadRequest
      raise ApiAccessNotEnabledError.new("API not enabled.")
    end

    raise InternalError.new("Invalid HTTP code: #{result.class}")
  end
end
