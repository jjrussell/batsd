class WinRedirectorController < AuthenticatedWinRedirectorController
  skip_before_filter :authenticate
  
end
