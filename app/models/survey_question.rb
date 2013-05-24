# == Schema Information
#
# Table name: survey_questions
#
#  id                 :string(36)      not null, primary key
#  survey_offer_id    :string(36)
#  text               :text            default(""), not null
#  possible_responses :text
#  format             :string(255)     not null
#  created_at         :datetime
#  updated_at         :datetime
#

class SurveyQuestion < ActiveRecord::Base
  include UuidPrimaryKey

  attr_reader :responses
  default_scope :order => 'position ASC'

  QUESTION_FORMATS = %w( select radio text )

  belongs_to :survey_offer

  validates_presence_of :text, :format, :position, :survey_offer
  validates_inclusion_of :format, :in => QUESTION_FORMATS

  before_validation :assign_position

  def to_s; text; end

  def responses=(val)
    self.possible_responses = val
  end

  def responses
    (self.possible_responses || '').split(';')
  end

private
  def assign_position
    if self.survey_offer
      self.survey_offer.reload
      self.position ||= (self.survey_offer.questions.size || 0) + 1
    end
  end
end
