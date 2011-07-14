# TO REMOVE: this controller when we shut down rackspace
class WinRedirectorController < AuthenticatedWinRedirectorController
  skip_before_filter :authenticate
  
end
