require 'cgi'

class QueueMessage
  
  def self.serialize(args)
    escaped_args = []
    args.each do |arg|
      escaped_args.push CGI::escape(arg)
    end
    
    return escaped_args.join(' ')
  end
  
  def self.deserialize(message)
    values = message.split(/ /)
    args = []
    values.each do |value|
      args.push(CGI::unescape(value))
    end
    
    return args
  end
end