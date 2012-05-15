class AppReview < ActiveRecord::Base
  BURY_LIMIT = 20
  include UuidPrimaryKey

  belongs_to :author, :polymorphic => true
  belongs_to :app_metadata

  has_many :helpful_votes
  has_many :bury_votes

  before_validation :set_is_blank
  after_save :update_app_metadata_rating_counts
  before_destroy :reset_app_metadata_rating_counts

  validates_uniqueness_of :author_id, :scope => :app_metadata_id, :if => :app_metadata, :message => "has already reviewed this app"
  validates_presence_of :author, :app_metadata
  validates_inclusion_of :user_rating, :in => [-1, 0, 1]

  scope :by_employees, :conditions => { :author_type => 'Employee' }
  scope :by_gamers, :conditions => { :author_type => 'Gamer' }
  scope :ordered_by_date, :order => "created_at DESC"

  delegate :name, :to => :app_metadata, :prefix => true

  cattr_reader :per_page
  @@per_page = 10

  def bury_by_author?(gamer_id)
    overlimit = bury_votes_count > BURY_LIMIT
    bad_ratio = bury_votes_count > helpful_votes_count + 1
    author_is_not_viewer = author_id != gamer_id
    overlimit && bad_ratio && author_is_not_viewer
  end

  def moderation_rating
    helpful_votes_count - bury_votes_count * 5
  end

  def user_rating=(new_rating)
    @prev_rating = user_rating || 0
    super(new_rating)
  end

  def author_name
    case author_type
    when 'Gamer'
      if !Rails.env.production? && author.nil?
        "Unknown Author"
      else
        author.get_gamer_nickname
      end
    when 'Employee'
      author.full_name
    end
  end

  def set_is_blank
    is_blank = text.blank?
    true
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
