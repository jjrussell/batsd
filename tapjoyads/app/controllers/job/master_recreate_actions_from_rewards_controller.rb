class Job::MasterRecreateActionsFromRewardsController < Job::JobController

  def index
    date = params[:date] ? params[:date] : Time.zone.now.strftime('%Y-%m-%d')
    Reward.recreate_actions_from_rewards(date)

    render :text => 'ok'
  end

end
