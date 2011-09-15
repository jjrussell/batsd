class PressRelease < ActiveRecord::Base
  include UuidPrimaryKey

  validates_presence_of :link_text, :link_href
  validates_presence_of :link_id, :content_title, :content_body, :unless => :external_press_release?
  validates_each :link_href do |record, attribute, value|
    begin
      record.errors.add(attribute, "must start with #{record.link_id}") unless value.starts_with?(record.link_id.to_s)
    rescue
      record.errors.add(attribute, "must start with #{record.link_id}")
    end
  end

  named_scope :ordered, :order => "link_id DESC"
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

private
  def external_press_release?
    link_href.starts_with?('http')
  end
end
