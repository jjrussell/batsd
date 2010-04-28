class ToolsController < UserController
  filter_access_to [ :payouts ]
  
  def index
  end
  
  def payouts
  end
  
end
