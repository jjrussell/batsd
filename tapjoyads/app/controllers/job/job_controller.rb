class Job::JobController < ApplicationController
  include AuthenticationHelper

  before_filter :authenticate

end
