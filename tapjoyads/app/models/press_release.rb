class PressRelease < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :link_text, :link_id, :link_href, :content_title, :content_body

  named_scope :ordered, :order => "published_at DESC"
  named_scope :not_future, :conditions => ["published_at < ?", Time.zone.now.end_of_day]

  def self.most_recent_and_not_future
    PressRelease.first( :order => "link_id DESC",
                       :conditions => ["content_body is not null and published_at < ?", Time.zone.now.end_of_day])
  end

  def future?
    published_at >= Date.today + 1.day
  end

  def seed_content_body
    self.content_body = <<-END.gsub(/^ {6}/, '')
      <p>- press_date
      Tapjoy, Inc. (<a href='https://www.tapjoy.com'>www.tapjoy.com</a>)
      </p>

      <p>
      </p>
    END
  end

  def content
    body = content_body
    location = body[/- press_date\((.*)\)/]
    if location.blank?
      body.gsub('- press_date', press_date)
    else
      location = location.gsub(/- press_date\(['"](.*)['"]\)/, '\1')
      body.gsub(/- press_date.*$/, press_date(location))
    end
  end

  def press_date(location="San Francisco, CA")
    "<b>#{location} &ndash; #{published_at.to_s(:pr)}</b> &ndash; "
  end

end
