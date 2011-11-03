class Job::MasterDeleteGamersController < Job::JobController
  def index
    Gamer.to_delete.each do |gamer|
      gamer.destroy
    end

    render :text => 'ok'
  end
end
