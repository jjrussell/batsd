class OneOffs

  def self.reshard_game_states
    count = 0
    num_correct = 0
    num_moved = 0
    num_already_moved = 0
    2.times do |i|
      domain_name = "game_states_#{i}"
      GameState.select(:domain_name => domain_name) do |gs|
        if count % 100 == 0
          puts "total: #{count}, num_correct: #{num_correct}, num_moved: #{num_moved}, num_already_moved: #{num_already_moved}"
        end
        count += 1
        correct_domain_name = "#{RUN_MODE_PREFIX}game_states_#{gs.key.matz_silly_hash % NUM_GAME_STATE_DOMAINS}"
        if gs.this_domain_name == correct_domain_name
          num_correct += 1
          next
        end
        gs2 = GameState.new(:key => gs.key)
        if gs2.attributes_to_replace.present?
          num_moved += 1
          gs2.save!
        else
          num_already_moved += 1
        end
        gs.delete_all(false)
      end
    end
    puts "total: #{count}, num_correct: #{num_correct}, num_moved: #{num_moved}, num_already_moved: #{num_already_moved}"
  end

end
