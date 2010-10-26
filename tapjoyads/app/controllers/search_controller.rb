class SearchController < WebsiteController

  filter_access_to :all
  
  def offers
    results = Offer.find(:all,
      :conditions => [ "name LIKE ?", "%#{params[:term]}%" ],
      :order => 'hidden ASC, name ASC',
      :limit => 10,
      :include => :partner
    ).collect do |o|
      { :label => o.search_result_name, :url => statz_path(o), :id => o.id }
    end

    render(:json => results.to_json)
  end
  
end