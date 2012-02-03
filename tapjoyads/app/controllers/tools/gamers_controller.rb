class Tools::GamersController < WebsiteController
  layout 'tabbed'
  current_tab :tools
  filter_access_to :all

  def index
  end

  def show
    @gamer = Gamer.find(params[:id])
    @gamer.gamer_profile ||= GamerProfile.new(:gamer => @gamer)
  end
end
