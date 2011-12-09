class Tools::GamersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
  end

  def show
  end
end
