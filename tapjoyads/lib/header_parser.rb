class HeaderParser
  def self.device_type(user_agent)
    case user_agent
    when /iphone;/i
      'iphone'
    when /ipod;/i
      'ipod'
    when /ipad;/i
      'ipad'
    when /android/i
      'android'
    when /windows/i
      'windows'
    else
      nil
    end
  end

  def self.os_version(user_agent)
    match = user_agent.match(/\((.*?)\)/)
    os_version = match[1].match(/(Android|iPhone OS) (.*?)[;|\s]/)[2].gsub('_', '.')
    os_version
  rescue Exception => e
    Rails.logger.info "Unable to parse os_version from user_agent: '#{user_agent}'"
    nil
  end

  def self.locale(accept_language)
    locale = accept_language.to_s.split(',').first
    language_code, country_code = locale.split(';').first.split('-') if locale.present?
    [language_code.try(:upcase), country_code.try(:upcase)]
  end
end
