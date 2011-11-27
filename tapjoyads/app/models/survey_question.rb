class SurveyQuestion < ActiveRecord::Base
  QUESTION_FORMATS = [
    'dropdown',
    'radio',
    'text',
  ]

  belongs_to :survey_offer

  validates_presence_of :text
  validates_presence_of :format
  validates_presence_of :survey_offer

  validates_inclusion_of :format, :in => QUESTION_FORMATS

  def to_s
    text
  end
end
