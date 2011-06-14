class Job::JobController < ApplicationController
  include AuthenticationHelper

  skip_before_filter :we_are_down
  before_filter :authenticate

end