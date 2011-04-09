class SearchController < WebsiteController

  filter_access_to :all
  
  def offers
    results = Offer.find(:all,
      :conditions => [ "name LIKE ?", "%#{params[:term]}%" ],
      :order => 'hidden ASC, name ASC',
      :limit => 10
    ).collect do |o|
      { :label => o.search_result_name, :url => statz_path(o), :id => o.id, :user_enabled => o.user_enabled, :daily_budget => o.daily_budget, :bid => o.bid, :payment => o.payment }
    end

    render(:json => results.to_json)
  end

  def users
    if params[:tapjoy_only] == 'true'
      email = "#{params[:term].split('@').first}%@tapjoy.com"
      results = User.find(:all,
        :conditions => [ "email LIKE ? AND email NOT LIKE ?", email, "%+%" ],
        :order => 'email ASC',
        :limit => 20
      )
    else
      results = User.find(:all,
        :conditions => [ "email LIKE ?", "#{params[:term]}%" ],
        :order => 'email ASC',
        :limit => 40
      )
    end
    results = results.map do |user|
      { :label => user.email, :user_id => user.id }
    end

    render(:json => results.to_json)
  end
end
