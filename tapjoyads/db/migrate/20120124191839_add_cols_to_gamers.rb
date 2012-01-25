class AddColsToGamers < ActiveRecord::Migration
  def self.up
    sql = [
      'ALTER TABLE gamers',
      'ADD COLUMN twitter_id VARCHAR(255),',
      'ADD COLUMN twitter_access_token VARCHAR(255),',
      'ADD COLUMN twitter_access_secret VARCHAR(255),',
      'ADD COLUMN extra_attributes VARCHAR(16777215),',
      'ADD INDEX index_gamers_on_twitter_id (twitter_id);',
    ].join(' ')
    execute(sql)
  end

  def self.down
    sql = [
      'ALTER TABLE gamers',
      'DROP COLUMN twitter_id,',
      'DROP COLUMN twitter_access_token,',
      'DROP COLUMN twitter_access_secret,',
      'DROP COLUMN extra_attributes,',
      'DROP INDEX index_gamers_on_twitter_id;',
    ].join(' ')
    execute(sql)
  end
end
