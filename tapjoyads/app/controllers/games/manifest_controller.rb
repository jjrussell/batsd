class Games::ManifestController < GamesController
  
  def show
    @content = ["CACHE MANIFEST"]
    @content << "# Version: 1.2"
    @content << "CACHE:"
    @content << '/favicon-tjgames.ico'
    @content << '/stylesheets/games/tapjoygames.css'
    if Rails.env.production? 
      @content << '/javascripts/games/tjgames.min-1.2.js'
    else
      @content << '/javascripts/games/src/jquery-1.4.2.js'
      @content << '/javascripts/games/src/init.js'
      @content << '/javascripts/games/src/jqtouch.js'
      @content << '/javascripts/games/src/tapjoygames.js'
    end
    @content << "NETWORK:"
    @content << "*" 
    render :text => @content.join("\n"), :content_type => 'text/cache-manifest', :layout => false
  end
  
end     