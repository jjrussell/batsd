namespace :experiments do
  desc 'Randomly assign all Devices into BUCKETS buckets with HASH_OFFSET hash offset'
  task :rehash_population => [:'experiments:clean'] do
    raise 'Please set BUCKETS env var to the number of buckets you would like' unless ENV['BUCKETS']
    buckets = ENV['BUCKETS'].to_i
    raise 'BUCKETS must be an integer greater than zero' unless buckets > 0

    offset = ENV['HASH_OFFSET'] || 0

    rehash_opts = {
      :buckets => buckets,
      :offset => offset,
      :chunk_size => 100
    }
    Rails.env.development? and rehash_opts.merge!(:limit => 1000)

    total_devices = rehash_opts[:limit] || Device.count

    puts "Hashing #{total_devices} devices into #{buckets} buckets"

    ExperimentBucket.rehash_population(rehash_opts) do |count|
      puts "#{count}/#{total_devices} devices assigned"
    end

    bucketed_devices = Device.count(:where => 'experiment_bucket_id is not null')

    puts "Hashed #{bucketed_devices} devices into #{ExperimentBucket.count} buckets"
    puts "Average bucket size is #{bucketed_devices.to_f / ExperimentBucket.count} devices"
  end

  if Rails.env.development?
    desc 'Destroy all experiments (freeing all devices)'
    task :reset => [:environment] do
      Experiment.destroy_all
    end
  end

  desc 'Destroy all experiments and buckets, clear bucket assignment from all Devices'
  task :clean => [:environment] do
    $redis.del('experiment_buckets')
    ExperimentBucket.destroy_all
    Experiment.destroy_all

    devices_to_clear = Device.count(:where => 'experiment_bucket_id is not null')
    puts "Un-bucketing #{devices_to_clear} devices"
    cleared = 0
    Device.select_all(:where => 'experiment_bucket_id is not null').each do |device|
      device.delete('experiment_bucket_id')
      device.save
      cleared += 1
      puts "Cleared #{cleared}" if cleared % 100 == 0
    end
  end
end
