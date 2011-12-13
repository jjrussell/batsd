class GamerReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app

  before_save :copy_platform

  validates_uniqueness_of :author_id, :scope => :app_id, :message => "has already reviewed this app"
  validates_presence_of :author, :app, :text

  named_scope :by_gamers, :conditions => { :author_type => 'Gamer' }
  named_scope :ordered_by_date, :order => "created_at DESC"
  named_scope :for_platform, lambda { |platform| { :conditions => [ "platform = ?", platform ] } }

  delegate :name, :id, :to => :app, :prefix => true
  delegate :get_gamer_name, :to => :author, :prefix => true

  private

  def copy_platform
    self.platform = app.platform
  end
end
