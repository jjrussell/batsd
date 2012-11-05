namespace :experiments do
  desc 'Create new experiment buckets and reset hashing parameters'
  task :rehash => [:'experiments:clean'] do
    raise 'Please set BUCKETS env var to the number of buckets you would like' unless ENV['BUCKETS']
    buckets = ENV['BUCKETS'].to_i
    raise 'BUCKETS must be an integer greater than zero' unless buckets > 0

    offset = ENV['HASH_OFFSET'] || 0

    rehash_opts = {
      :buckets => buckets,
      :offset => offset
    }

    ExperimentBucket.rehash_population(rehash_opts)

    puts "Average bucket size is #{ExperimentBucket.average_size} devices"
  end

  desc 'Destroy all experiments and buckets, clear bucket assignment from all Devices'
  task :clean => [:environment] do
    $redis.del(ExperimentBucket::LOOKUP_KEY, ExperimentBucket::OFFSET_KEY)
    ExperimentBucket.destroy_all
  end

  if Rails.env.development?
    desc 'Destroy all experiments and buckets'
    task :reset => [:'experiments:clean'] do
      Experiment.destroy_all
    end
  end
end
