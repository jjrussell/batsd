class PressRelease < ActiveRecord::Base
  include UuidPrimaryKey

  named_scope :ordered, :order => "published_at DESC"
  def self.most_recent
    PressRelease.first( :order => "published_at DESC", :conditions => "content_body is not null")
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
