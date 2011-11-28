class CreateSurveyQuestions < ActiveRecord::Migration
  def self.up
    create_table :survey_questions do |t|
      t.guid   :survey_offer_id
      t.text :text, :null => false
      t.text :possible_responses
      t.string :format, :null => false

      t.timestamps
    end

    add_index :survey_questions, :survey_offer_id
  end

  def self.down
    remove_index :survey_questions, :survey_offer_id

    drop_table :survey_questions
  end
end
