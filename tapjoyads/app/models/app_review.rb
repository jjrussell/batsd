class AppReview < ActiveRecord::Base
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app_metadata

  after_save :update_app_metadata_rating_counts
  before_destroy :reset_app_metadata_rating_counts

  validates_uniqueness_of :author_id, :scope => :app_metadata_id, :if => :app_metadata, :message => "has already reviewed this app"
  validates_presence_of :author, :app_metadata, :text
  validates_inclusion_of :user_rating, :in => [-1, 0, 1]

  named_scope :by_employees, :conditions => { :author_type => 'Employee' }
  named_scope :by_gamers, :conditions => { :author_type => 'Gamer' }
  named_scope :ordered_by_date, :order => "created_at DESC"

  delegate :name, :to => :app_metadata, :prefix => true

  cattr_reader :per_page
  @@per_page = 10

  def user_rating=(new_rating)
    @prev_rating = user_rating || 0
    super(new_rating)
  end

  def author_name
    case author_type
    when 'Gamer'
      author.get_gamer_name
    when 'Employee'
      author.full_name
    end
  end

  private

  def update_app_metadata_rating_counts
    return if @prev_rating.nil? || user_rating == @prev_rating

    if user_rating > 0
      app_metadata.increment!(:thumbs_up)
      app_metadata.decrement!(:thumbs_down) if @prev_rating < 0
    elsif user_rating < 0
      app_metadata.increment!(:thumbs_down)
      app_metadata.decrement!(:thumbs_up) if @prev_rating > 0
    else
      app_metadata.decrement!(:thumbs_down) if @prev_rating < 0
      app_metadata.decrement!(:thumbs_up) if @prev_rating > 0
    end
  end

  def reset_app_metadata_rating_counts
    if user_rating > 0
      app_metadata.decrement!(:thumbs_up)
    elsif user_rating < 0
      app_metadata.decrement!(:thumbs_down)
    end
  end
end
