require 'spec_helper'

describe Dashboard::Tools::GamersController do
  
  PERMISSIONS_MAP = {
    :index => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service_manager => true,
        :customer_service         => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    },
    
    :show => {
      :permissions => {
        :account_manager          => true,
        :admin                    => true,
        :agency                   => false,
        :customer_service_manager => true,
        :customer_service         => true,
        :devices                  => false,
        :executive                => false,
        :file_sharer              => false,
        :games_editor             => false,
        :hr                       => false,
        :money                    => false,
        :ops                      => false,
        :products                 => false,
        :partner                  => false,
        :partner_changer          => false,
        :payops                   => false,
        :payout_manager           => false,
        :reporting                => false,
        :role_manager             => false,
        :sales_rep_manager        => false,
        :tools                    => false
      }
    }
  } unless defined? PERMISSIONS_MAP
  
  it_behaves_like "a controller with permissions"
end
