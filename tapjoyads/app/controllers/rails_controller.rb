class RailsController < ApplicationController
  def info
    # Ruby 1.8 hashes are not ordered, so you can't simply wrap the original hash :(
    info = ActiveSupport::OrderedHash.new
    info[:environment]   = Rails.env
    info[:git_rev]       = GIT_REV
    info[:git_branch]    = GIT_BRANCH
    info[:host_name]     = HOSTNAME
    info[:time_now]      = Time.now
    info[:time_zone_now] = Time.zone.now
    info[:time_zone]     = Time.zone.name
    info[:machine_type]  = MACHINE_TYPE

    render :json => info
  end
end
