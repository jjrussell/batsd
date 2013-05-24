class TapjoyAd
  attr_accessor :click_url, :image, :ad_message, :ad_impression_id, :ad_id, :ad_html, :open_in, :game_id

  def initialize()
    @game_id = "00000000-0000-0000-0000-000000000000"
    @ad_impression_id = "00000000-0000-0000-0000-000000000000"
    @ad_id = "00000000-0000-0000-0000-000000000000"
    @ad_html = nil
    @open_in = "Safari"
    @ad_message = nil
  end
end
