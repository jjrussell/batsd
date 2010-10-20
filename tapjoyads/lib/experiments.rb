class Experiments
  EXPERIMENTS = {
    :no_change => '1',
  }
  
  def self.choose(udid)
    if udid.present?
      udid_hash = udid.hash % 10000

      if udid_hash < 100
        return EXPERIMENTS[:no_change]
      end
      
      return nil
    end
  end
  
  def self.report(start_time, end_time, experiment_id)
    # For the math and a detailed explanation of the process see:
    # http://20bits.com/articles/statistical-analysis-and-ab-testing/
    
    # Prefixes: "c_" is the control group. "e_" is the experimental group.
    
    experiment_id = experiment_id.to_s
    
    viewed_at_condition = "viewed_at >= '#{start_time.to_i}' and viewed_at < '#{end_time.to_i}'"
    
    c_offerwall_views = c_clicks = c_conversions = e_offerwall_views = e_clicks = e_conversions = 0
    
    date = start_time.to_date
    while date <= end_time.to_date + 2.days && date <= Time.zone.now.to_date
      puts date
      
      c_offerwall_views += WebRequest.count :date => date, :where => "path = 'offers' and time >= '#{start_time.to_i}' and time < '#{end_time.to_i}' and exp is null"
      e_offerwall_views += WebRequest.count :date => date, :where => "path = 'offers' and time >= '#{start_time.to_i}' and time < '#{end_time.to_i}' and exp = '#{experiment_id}'"
      
      c_clicks += WebRequest.count :date => date, :where => "path = 'offer_click' and #{viewed_at_condition} and exp is null"
      e_clicks += WebRequest.count :date => date, :where => "path = 'offer_click' and #{viewed_at_condition} and exp = '#{experiment_id}'"
      
      c_conversions += WebRequest.count :date => date, :where => "path = 'conversion' and #{viewed_at_condition} and exp is null"
      e_conversions += WebRequest.count :date => date, :where => "path = 'conversion' and #{viewed_at_condition} and exp = '#{experiment_id}'"
      
      date += 1.day
    end
    
    c_revenues = []
    e_revenues = []
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select :domain_name => "rewards_#{i}", :where => viewed_at_condition do |reward|
        if reward.exp.nil?
          c_revenues << reward.publisher_amount
        elsif reward.exp == experiment_id
          e_revenues << reward.publisher_amount
        end
      end
    end
    
    c_ctr = c_clicks.to_f / c_offerwall_views
    c_cvr = c_conversions.to_f / c_clicks
    c_avg_rev = c_revenues.sum.to_f / c_offerwall_views

    e_ctr = e_clicks.to_f / e_offerwall_views
    e_cvr = e_conversions.to_f / e_clicks
    e_avg_rev = e_revenues.sum.to_f / e_offerwall_views

    c_ctr_variance = c_offerwall_views == 0 ? 0 : (c_ctr * (1 - c_ctr)) / c_offerwall_views
    e_ctr_variance = e_offerwall_views == 0 ? 0 : (e_ctr * (1 - e_ctr)) / e_offerwall_views
    
    c_cvr_variance = c_clicks == 0 ? 0 : (c_cvr * (1 - c_cvr)) / c_clicks
    e_cvr_variance = e_clicks == 0 ? 0 : (e_cvr * (1 - e_cvr)) / e_clicks

    c_rev_diff_mean_squares = []
    c_offerwall_views.times do |i|
      rev = c_revenues[i] || 0
      c_rev_diff_mean_squares << (rev - c_avg_rev) ** 2
    end
    c_rev_variance = c_offerwall_views == 0 ? 0 : c_rev_diff_mean_squares.sum.to_f / c_offerwall_views
    
    e_rev_diff_mean_squares = []
    e_offerwall_views.times do |i|
      rev = e_revenues[i] || 0
      e_rev_diff_mean_squares << (rev - e_avg_rev) ** 2
    end
    e_rev_variance = e_offerwall_views == 0 ? 0 : e_rev_diff_mean_squares.sum.to_f / e_offerwall_views

    ctr_z_score = (e_ctr - c_ctr) / Math.sqrt(e_ctr_variance + c_ctr_variance)
    cvr_z_score = (e_cvr - c_cvr) / Math.sqrt(e_cvr_variance + c_cvr_variance)
    avg_rev_z_score = (e_avg_rev - c_avg_rev) / Math.sqrt(e_rev_variance + c_rev_variance)
    
    puts <<-END
    Control group
      Offerwall views:  #{c_offerwall_views}
      Clicks:           #{c_clicks}
      Conversions:      #{c_conversions}
      Revenue:          $#{c_revenues.sum / 100.0}
      CTR:              #{c_ctr}
      CVR:              #{c_cvr}
      Avg revenue:      $#{c_avg_rev / 100.0}
    Experimental group
      Offerwall views:  #{e_offerwall_views}
      Clicks:           #{e_clicks}
      Conversions:      #{e_conversions}
      Revenue:          $#{e_revenues.sum / 100.0}
      CTR:              #{e_ctr}
      CVR:              #{e_cvr}
      Avg revenue:      $#{e_avg_rev / 100.0}
    
    Variance (used to calculate z-scores)
      Control
        ctr: #{c_ctr_variance}, cvr: #{c_cvr_variance}, revenue: #{c_rev_variance}
      Experimental
        ctr: #{e_ctr_variance}, cvr: #{e_cvr_variance}, revenue: #{e_rev_variance}
      
    Improvement (z-scores >= 1.645 represents 95% confidence that difference is not due to random variance)
      CTR Z-score:         #{ctr_z_score}
      CVR Z-score:         #{cvr_z_score}
      Avg Revenue Z-score: #{avg_rev_z_score}
    END
  end
end