class RackspaceController < ApplicationController
  skip_before_filter :set_time_zone
  skip_before_filter :set_locale
  skip_before_filter :fix_params
  skip_before_filter :reject_banned_ips
  before_filter :rackspace_is_gone

private

  def rackspace_is_gone
    render :template => 'layouts/success'
  end

end
