class HomeController < WebsiteController
  layout 'tabbed'
  
  filter_access_to :all
  
end
