require 'spec_helper'

describe Dashboard::Tools::NoticesController do

  PERMISSIONS_MAP = {
    :index  => { :allowed => [ :admin, :products ]},
    :update => { :allowed => [ :admin, :products ]}
  }

  it_behaves_like "a controller with permissions"

end
