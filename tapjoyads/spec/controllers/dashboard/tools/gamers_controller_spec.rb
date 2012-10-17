require 'spec_helper'

describe Dashboard::Tools::GamersController do

  PERMISSIONS_MAP = {
    :index  => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
    :show   => { :allowed => [ :account_mgr, :admin, :customer_service_manager, :customer_service, :payout_manager, :payops ]},
  }

  it_behaves_like "a controller with permissions"

end
