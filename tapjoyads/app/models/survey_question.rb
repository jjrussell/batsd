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

  QUESTION_FORMATS = %w( select radio text )

  belongs_to :survey_offer

  validates_presence_of :text
  validates_presence_of :format
  validates_presence_of :survey_offer

  validates_inclusion_of :format, :in => QUESTION_FORMATS

  def to_s
    text
  end

  def possible_responses
    super.split(';')
  end
end
