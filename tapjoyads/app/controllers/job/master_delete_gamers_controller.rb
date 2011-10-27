class Job::MasterDeleteGamersController < Job::JobController
  def index
    Gamer.to_delete.each do |gamer|
      gamer.destroy
      sleep 5
    end

    render :text => 'ok'
  end
end
