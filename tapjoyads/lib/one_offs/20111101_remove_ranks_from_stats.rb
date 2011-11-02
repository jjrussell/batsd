class OneOffs

  def self.remove_ranks_from_stats
    count = 0
    Stats.select(:where => "ranks is not null") do |stat|
      rank_keys = stat.attributes.keys.select { |k| k.starts_with?('ranks') }
      rank_keys.each do |k|
        stat.delete(k)
      end
      begin
        stat.save!
      rescue
        puts "retrying..."
        sleep 1
        retry
      end
      count += 1
      puts count if count % 1000 == 0
    end
    count
  end

end
