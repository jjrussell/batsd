class Games::TapjoygamesController < GamesController
  def index
    respond_to do |format|
      format.mobileconfig
    end
  end
end