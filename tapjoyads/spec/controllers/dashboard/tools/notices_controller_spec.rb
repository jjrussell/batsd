require 'spec_helper'

describe Dashboard::Tools::NoticesController do

  it_behaves_like "a controller with permissions", {
    :index  => { :allowed => [ :admin, :products ]},
    :update => { :allowed => [ :admin, :products ]}
  }

end
