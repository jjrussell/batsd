object false
node :pager do
  { :count_items => @pagination_info[:count_items], 
  					 :count_pages => @pagination_info[:count_pages], 
  					 :current_page => @pagination_info[:current_page], 
  					 :per_page => @pagination_info[:per_page] } 
end
