class ExactTarget
  extend Savon::Model
  
  document File.expand_path("../../../lib/exact_target/etframework.wsdl.xml", __FILE__)
  wsse_auth "tapbrian", "welcome@2"
  
  actions :get_system_status, :version_info
  
  def get_system_status
    response = super
    if response.success?
      response.to_array(:system_status_response_msg)
    end
  end
end
