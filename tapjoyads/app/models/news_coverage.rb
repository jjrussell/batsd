# == Schema Information
#
# Table name: news_coverages
#
#  id           :string(36)      not null, primary key
#  published_at :datetime        not null
#  link_source  :string(255)     not null
#  link_text    :text            default(""), not null
#  link_href    :text            default(""), not null
#  created_at   :datetime
#  updated_at   :datetime
#

class NewsCoverage < ActiveRecord::Base
  include UuidPrimaryKey

  scope :ordered, :order => "published_at DESC"
  scope :not_future, :conditions => ["published_at < ?", Time.zone.now.end_of_day]
end
