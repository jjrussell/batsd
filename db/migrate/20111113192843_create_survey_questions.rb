class CreateSurveyQuestions < ActiveRecord::Migration
  def self.up
    create_table :survey_questions, :id => false do |t|
      t.guid    :id, :null => false
      t.guid   :survey_offer_id
      t.text :text, :null => false
      t.text :possible_responses
      t.string :format, :null => false

      t.timestamps
    end

    add_index :survey_questions, :id, :unique => true
    add_index :survey_questions, :survey_offer_id
  end

  def self.down
    remove_index :survey_questions, :id
    remove_index :survey_questions, :survey_offer_id

    drop_table :survey_questions
  end
end
