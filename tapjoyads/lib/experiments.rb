class Experiments
  EXPERIMENTS = {
    :default => '0',
    :papaya_on => '1',
    :papaya_off => '2'
  }

  def self.choose(udid)
    if udid.present?
      udid.hash % 2 == 0 ? EXPERIMENTS[:papaya_on] : EXPERIMENTS[:papaya_off]
    end
  end

  def self.report(start_time, end_time, experiment_id, control_id = EXPERIMENTS[:control])
    # For the math and a detailed explanation of the process see:
    # http://20bits.com/articles/statistical-analysis-and-ab-testing/

    # Prefixes: "c_" is the control group. "e_" is the experimental group.

    puts "Report for experiment group '#{experiment_id}' and control group '#{control_id}', from #{start_time.to_s} to #{end_time.to_s}"

    report_multiple(start_time, end_time, [ experiment_id ], control_id)
  end

  def self.get_experiment_data(start_time, end_time, experiment_id)
    experiment_id = experiment_id.to_s
    viewed_at_condition_sdb = "viewed_at >= '#{start_time.to_i}' AND viewed_at < '#{end_time.to_i}'"
    viewed_at_condition_vertica = "viewed_at >= #{start_time.to_i} AND viewed_at < #{end_time.to_i}"
    offerwall_views = clicks = conversions = 0
    revenues = []
    date = start_time.to_date

    while date <= end_time.to_date + 2.days && date <= Time.zone.now.to_date
      offerwall_views += WebRequest.count "path = '[offers]' AND #{viewed_at_condition_vertica} AND exp = '#{experiment_id}'"
      clicks += WebRequest.count "path = '[offer_click]' AND #{viewed_at_condition_vertica} AND exp = '#{experiment_id}'"
      conversions += WebRequest.count "path = '[reward]' AND #{viewed_at_condition_vertica} AND exp = '#{experiment_id}'"
      date += 1.day
    end

    NUM_REWARD_DOMAINS.times do |i|
      Reward.select :domain_name => "rewards_#{i}", :where => "#{viewed_at_condition_sdb} AND (exp = '#{experiment_id}')" do |reward|
        revenues << reward.publisher_amount
      end
    end

    ctr       = clicks.to_f / offerwall_views
    cvr       = conversions.to_f / clicks
    total_rev = revenues.sum.to_f
    avg_rev   = total_rev / offerwall_views
    revenues  = revenues + Array.new(offerwall_views - revenues.length) { 0 }

    ctr_variance = offerwall_views == 0 ? 0 : (ctr * (1 - ctr)) / offerwall_views
    cvr_variance = clicks == 0 ? 0 : (cvr * (1 - cvr)) / clicks
    rev_variance = revenues.variance

    { :clicks => clicks, :offerwall_views => offerwall_views, :conversions => conversions,
      :ctr => ctr, :cvr => cvr, :avg_rev => avg_rev, :total_rev => total_rev,
      :ctr_variance => ctr_variance, :cvr_variance => cvr_variance, :rev_variance => rev_variance, :name => experiment_id }
  end

  def self.report_multiple(start_time, end_time, experiment_ids, control_id = EXPERIMENTS[:control], csv_filename = nil)
    puts "Report started at: #{Time.zone.now}"
    puts "Start time: #{start_time}"
    puts "End time: #{end_time}"
    control = get_experiment_data(start_time, end_time, control_id).merge({ :name => 'Control' })

    if csv_filename
      csv = File.new(csv_filename, 'w')
      puts "Writing to #{csv_filename}..."
      csv.puts <<-END
Experiment Group,Views,Clicks,Conversions,Revenue,CTR,CVR,AvgRev,CTR-Z,CVR-Z,AvgRev-Z,AvgRevChange
Control,#{control[:offerwall_views]},#{control[:clicks]},#{control[:conversions]},$#{control[:total_rev] / 100.0},#{control[:ctr]},#{control[:cvr]},$#{control[:avg_rev] / 100.0},0,0,0,0
      END
      puts "Wrote Control Group"
    else
      print_data(control)
    end

    experiment_ids.each do |experiment_id|
      experiment = calculate_z_scores(get_experiment_data(start_time, end_time, experiment_id), control)
      if csv_filename
        puts "Wrote #{experiment_id}"
        csv.puts "#{experiment_id},#{experiment[:offerwall_views]},#{experiment[:clicks]},#{experiment[:conversions]},$#{experiment[:total_rev] / 100.0},#{experiment[:ctr]},#{experiment[:cvr]},$#{experiment[:avg_rev] / 100.0},#{experiment[:ctr_z_score]},#{experiment[:cvr_z_score]},#{experiment[:avg_rev_z_score]},#{experiment[:avg_rev_change]}"
      else
        print_data(experiment)
      end
    end

    csv.close if csv_filename

    puts "Report finished at: #{Time.zone.now}"
  end

  def self.calculate_z_scores(experiment, control)
    experiment[:ctr_z_score] = (experiment[:ctr] - control[:ctr]) / Math.sqrt(experiment[:ctr_variance] + control[:ctr_variance])
    experiment[:cvr_z_score] = (experiment[:cvr] - control[:cvr]) / Math.sqrt(experiment[:cvr_variance] + control[:cvr_variance])
    experiment[:avg_rev_z_score] = (experiment[:avg_rev] - control[:avg_rev]) / Math.sqrt(experiment[:rev_variance] + control[:rev_variance])
    experiment[:avg_rev_change] = (experiment[:avg_rev] - control[:avg_rev]) / control[:avg_rev] * 100
    experiment
  end

  def self.print_data(experiment)
    puts <<-END
    #{experiment[:name]}
      Offerwall views:  #{experiment[:offerwall_views]}
      Clicks:           #{experiment[:clicks]}
      Conversions:      #{experiment[:conversions]}
      Revenue:          $#{experiment[:total_rev] / 100.0}
      CTR:              #{experiment[:ctr]}
      CVR:              #{experiment[:cvr]}
      Avg revenue:      $#{experiment[:avg_rev] / 100.0}
      CTR-Z:            #{experiment[:ctr_z_score] || 0}
      CVR-Z:            #{experiment[:cvr_z_score] || 0}
      Avg Revenue Z:    #{experiment[:avg_rev_z_score] || 0}
      Avg Rev Change:   #{experiment[:avg_rev_change] || 0}%
    END
  end
end
