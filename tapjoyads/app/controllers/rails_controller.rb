class RailsController < ApplicationController
  def info
    info = {
      :environment => Rails.env,
      :git_rev => GIT_REV,
      :git_branch => GIT_BRANCH,
      :host_name => HOSTNAME,
      :time_now => Time.now,
      :time_zone_now => Time.zone.now,
      :time_zone => Time.zone,
      :machine_type => MACHINE_TYPE
    }
    render :json => info
  end
end
