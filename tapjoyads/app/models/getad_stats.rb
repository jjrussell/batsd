require 'cgi'

class GetadStats
  attr_accessor :app_id, :ad_returned
  
  def initialize(app_id, ad_returned)
    @app_id = app_id
    @ad_returned = ad_returned
  end
  
  def serialize
    [CGI::escape(@app_id),
     @ad_returned ? '1' : '0'].join(' ')
  end
  
  def self.deserialize(message)
    values = message.split(' ')
    GetadStats.new(CGI::unescape(values[0]), values[1] == '1')
  end
end