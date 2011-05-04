class PressRelease < ActiveRecord::Base
  named_scope :recent, lambda { |num| { :order => "published_at DESC", :limit => num } }
  def self.most_recent
    recent(1)[0]
  end

  def content
    body = content_body
    press_date = "<strong>San Francisco, CA &ndash; #{published_at.to_s(:pr)}</strong> &ndash; "
    body.gsub!('- press_date', press_date)
    body.gsub!(/- about_blurb.*$/, <<-END.gsub(/^ {6}/, '')
      <h2>About Tapjoy, Inc.</h2>
      <p>Tapjoy is the leading platform company for social and mobile applications,
      helping app developers acquire new users, maximize revenue and deepen user
      engagement. The company's distribution network spans more than 9,000
      applications and 300 million total end-users on iOS, Android and social
      platforms, delivering over 1 million high-value customers each day to brand
      advertisers, direct marketers and app developers. The Tapjoy monetization
      engine maximizes revenue for publishers by providing a frictionless payment
      system for virtual goods and premium digital assets. Tapjoy is venture-backed
      and headquartered in San Francisco, with offices in Silicon Valley, New York,
      London and Japan. For more, visit <a href='https://www.tapjoy.com/'>www.tapjoy.com</a>.</p>
    END
    )

    base = Class.new do
      include ActionView::Helpers::UrlHelper
      include PressHelper
    end.new
    Haml::Engine.new(body).render(base)
  end

  def press_date(location="San Francisco, CA")
    date_string = "#{params[:id][0..3]}-#{params[:id][4..5]}-#{params[:id][6..7]}"
    date = Date.parse(date_string).strftime("%B %-1d, %Y")
    location = "Fremont, CA" if location == :fremont
    "<strong>#{location} &ndash; #{date}</strong> &ndash; "
  end
end
