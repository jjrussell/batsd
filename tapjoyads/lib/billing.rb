class Billing

  AUTH_NET_LOGIN    = '6d68x2KxXVM'
  AUTH_NET_PASSWORD = '6fz7YyU9424pZDc6'
  SUCCESS_MSG       = 'success'
  NO_CIM_MSG        = 'no CIM number'

  def self.get_gateway
    ActiveMerchant::Billing::AuthorizeNetGateway.new(:login => AUTH_NET_LOGIN, :password => AUTH_NET_PASSWORD, :test => Rails.env != 'production')
  end

  def self.get_cim_gateway
    ActiveMerchant::Billing::AuthorizeNetCimGateway.new(:login => AUTH_NET_LOGIN, :password => AUTH_NET_PASSWORD, :test => Rails.env != 'production')
  end

  def self.charge_credit_card(credit_card, amount, partner_id)
    get_gateway.purchase(amount, credit_card, { :description => partner_id })
  end

  def self.charge_payment_profile(user, payment_profile_id, amount_cents, partner_id)
    request_hash = {
      :transaction => {
        :customer_profile_id         => user.auth_net_cim_id,
        :customer_payment_profile_id => payment_profile_id,
        :type                        => :auth_capture,
        :amount                      => (amount_cents / 100.0).to_s,
        :order                       => { :description => partner_id }
      }
    }
    response = get_cim_gateway.create_customer_profile_transaction(request_hash)
    if response.success? && response.params['direct_response'].present?
      response.params['transaction_id'] = response.params['direct_response']['transaction_id']
    end
    response
  end

  def self.create_customer_profile(user)
    return SUCCESS_MSG if user.auth_net_cim_id.present?

    request_hash = {
      :profile => {
        :email => user.email,
        :description => user.id
      }
    }
    response = get_cim_gateway.create_customer_profile(request_hash)
    if response.success?
      user.auth_net_cim_id = response.authorization
      user.save!
      SUCCESS_MSG
    else
      response.message
    end
  end

  def self.update_customer_profile(user)
    return NO_CIM_MSG if user.auth_net_cim_id.blank?

    request_hash = {
      :profile => {
        :customer_profile_id => user.auth_net_cim_id,
        :email => user.email,
        :description => user.id
      }
    }
    response = get_cim_gateway.update_customer_profile(request_hash)
    response.success? ? SUCCESS_MSG : response.message
  end

  def self.delete_customer_profile(user)
    return SUCCESS_MSG if user.auth_net_cim_id.blank?

    response = get_cim_gateway.delete_customer_profile({ :customer_profile_id => user.auth_net_cim_id })
    if response.success?
      user.auth_net_cim_id = nil
      user.save!
      SUCCESS_MSG
    else
      response.message
    end
  end

  def self.get_customer_profile(user)
    return {} if user.auth_net_cim_id.blank?

    response = get_cim_gateway.get_customer_profile({ :customer_profile_id => user.auth_net_cim_id })
    response.success? ? response.params['profile'] : {}
  end

  def self.create_payment_profile(user, credit_card)
    return NO_CIM_MSG if user.auth_net_cim_id.blank?

    request_hash = {
      :customer_profile_id => user.auth_net_cim_id,
      :payment_profile => {
        :payment => { :credit_card => credit_card }
      }
    }
    response = get_cim_gateway.create_customer_payment_profile(request_hash)
    response.success? ? SUCCESS_MSG : response.message
  end

  def self.delete_payment_profile(user, payment_profile_id)
    return NO_CIM_MSG if user.auth_net_cim_id.blank?

    request_hash = {
      :customer_profile_id         => user.auth_net_cim_id,
      :customer_payment_profile_id => payment_profile_id
    }
    response = get_cim_gateway.delete_customer_payment_profile(request_hash)
    response.success? ? SUCCESS_MSG : response.message
  end

  def self.get_payment_profiles(user)
    return [] if user.auth_net_cim_id.blank?

    payment_profiles = []
    customer_profile = get_customer_profile(user)
    if customer_profile['payment_profiles'].present?
      payment_profiles = customer_profile['payment_profiles']
      payment_profiles = [ payment_profiles ] unless payment_profiles.is_a?(Array)
    end

    payment_profiles
  end

  def self.get_payment_profiles_for_select(user)
    payment_profiles = get_payment_profiles(user).map do |pp|
      display_number = pp['payment']['credit_card']['card_number']
      [ "Ending in #{display_number[0, 4]}-#{display_number[4, 4]}", pp['customer_payment_profile_id'] ]
    end
    payment_profiles << [ 'New Card', 'new_card' ]
  end

end
