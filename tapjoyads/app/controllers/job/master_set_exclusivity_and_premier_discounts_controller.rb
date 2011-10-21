class Job::MasterSetExclusivityAndPremierDiscountsController < Job::JobController
  def index
    PremierTasks.set_exclusivity_and_premier_discounts
    render :text => "ok"
  end
end
