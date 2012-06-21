require 'spec_helper'

describe Dashboard::Tools::GamersController do
  
  PERMISSIONS_MAP = {
    :index => {
      :permissions => {
        :account_manager        => true,
        :customer_service_user  => true,
        :partner                => false
      }
    },
    
    :show => {
      :params => {
        :id => FactoryGirl.create(:gamer).id
      },
      :permissions => {
        :account_manager        => true,
        :customer_service_user  => true,
        :partner                => false
      }
    }
  } unless defined? PERMISSIONS_MAP
  it_behaves_like "a controller with permissions"
  
end
