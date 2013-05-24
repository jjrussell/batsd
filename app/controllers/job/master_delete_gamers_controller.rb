class Job::MasterDeleteGamersController < Job::JobController
  def index
    today = Date.today
    key = "deleted_gamers/#{today.strftime('%Y-%m')}"
    object = S3.bucket(BucketNames::TAPJOY).objects[key]
    data = object.exists? ? object.read : ''
    data = "#{data}#{today.to_s}: #{Gamer.to_delete.count}\n"
    object.write(:data => data)

    Gamer.to_delete.destroy_all

    render :text => 'ok'
  end
end
