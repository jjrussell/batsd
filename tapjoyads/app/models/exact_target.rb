class ExactTarget
  extend Savon::Model
  
  TJM_WELCOME_EMAIL_ETID = 'tjm_welcome'
  
  document "https://webservice.s6.exacttarget.com/etframework.wsdl"
  wsse_auth "tapbrian", "welcome@2"
  
  actions :get_system_status
  
  def get_system_status
    response = super
    if response.success?
      response.to_array(:system_status_response_msg)
    end
  end
end
