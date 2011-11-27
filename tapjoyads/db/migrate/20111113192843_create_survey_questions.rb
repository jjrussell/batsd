class CreateSurveyQuestions < ActiveRecord::Migration
  def self.up
    create_table :survey_questions do |t|
      t.guid   :survey_offer_id
      t.string :text, :null => false
      t.string :format, :null => false
      t.string :possible_responses

      t.timestamps
    end
  end

  def self.down
    drop_table :survey_questions
  end
end
