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
  
  def self.report(date, experiment_id)
    # For the math and a detailed explanation of the process see:
    # http://20bits.com/articles/statistical-analysis-and-ab-testing/
    
    # Prefixes: "c_" is the control group. "e_" is the experimental group.
    
    start_time = Date.parse(date).to_time
    end_time = start_time + 1.day
    experiment_id = experiment_id.to_s
    
    c_offerwall_views = WebRequest.count :date => date, :where => "path = 'offers' and exp is null"
    c_clicks = WebRequest.count :date => date, :where => "path = 'offer_click' and exp is null"
    c_conversions = WebRequest.count :date => date, :where => "path = 'conversion' and exp is null"
    e_offerwall_views = WebRequest.count :date => date, :where => "path = 'offers' and exp = '#{experiment_id}'"
    e_clicks = WebRequest.count :date => date, :where => "path = 'offer_click' and exp = '#{experiment_id}'"
    e_conversions = WebRequest.count :date => date, :where => "path = 'conversion' and exp = '#{experiment_id}'"
    
    c_revenues = []
    e_revenues = []
    NUM_REWARD_DOMAINS.times do |i|
      Reward.select :domain_name => "rewards_#{i}", :where => "created >= '#{start_time.to_i}' and created < '#{end_time.to_i}'" do |reward|
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
    c_rev_variance = c_rev_diff_mean_squares.sum.to_f / c_rev_diff_mean_squares.size
    
    e_rev_diff_mean_squares = []
    e_offerwall_views.times do |i|
      rev = e_revenues[i] || 0
      e_rev_diff_mean_squares << (rev - e_avg_rev) ** 2
    end
    e_rev_variance = e_rev_diff_mean_squares.sum.to_f / e_rev_diff_mean_squares.size

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