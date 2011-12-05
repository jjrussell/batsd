require 'test_helper'

class AgencyApi::PartnersControllerTest < ActionController::TestCase

  context "on GET to :index" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner, :balance => 10, :pending_earnings => 11, :name => 'name', :contact_name => 'contact_name')
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = get(:index)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = get(:index, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        expected_response = {
          'partner_id'       => @partner.id,
          'name'             => @partner.name,
          'balance'          => @partner.balance,
          'pending_earnings' => @partner.pending_earnings,
          'contact_email'    => @partner.contact_name,
        }
        assert_equal [expected_response], result['partners']
      end
    end
  end

  context "on GET to :show" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner, :balance => 10, :pending_earnings => 11, :name => 'name', :contact_name => 'contact_name')
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
      @partner2 = Factory(:partner)
    end
    context "with missing params" do
      setup do
        @response = get(:index, :id => 'not_a_partner_id')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = get(:index, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid partner_id" do
      setup do
        @response = get(:show, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with a partner_id not belonging to the agency" do
      setup do
        @currency2 = Factory(:currency)
        @response = get(:show, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = get(:show, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @partner.id, result['partner_id']
        assert_equal @partner.name, result['name']
        assert_equal @partner.balance, result['balance']
        assert_equal @partner.pending_earnings, result['pending_earnings']
        assert_equal @partner.contact_name, result['contact_email']
      end
    end
  end

  context "on POST to :create" do
    setup do
      @reseller = Factory(:reseller)
      @agency_user = Factory(:agency_user, :reseller => @reseller)
    end

    context "with missing params" do
      setup do
        @response = post(:create)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => 'foo', :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with invalid params" do
      setup do
        Factory(:user, :email => 'email@example.com')
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = post(:create, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner', :email => 'email@example.com')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        user = User.find_by_email('email@example.com')
        assert_equal 1, user.partners.count
        partner = user.partners.first
        assert_equal partner.id, result['partner_id']
        assert_equal 'partner', partner.name
        assert_equal @reseller.id, partner.reseller_id
      end
    end
  end

  context "on POST to :link" do
    setup do
      @agency_user = Factory(:agency_user)
      @user = Factory(:user)
      @partner = Factory(:partner)
      PartnerAssignment.create!(:user => @user, :partner => @partner)
    end

    context "with missing params" do
      setup do
        @response = post(:link)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => 'foo', :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad user credentials" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid email" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => 'email@example.com', :user_api_key => @user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "for a user with too many partner accounts" do
      setup do
        @partner2 = Factory(:partner)
        PartnerAssignment.create!(:user => @user, :partner => @partner2)
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = post(:link, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :email => @user.email, :user_api_key => @user.api_key)
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        assert result['success']
        assert_equal @partner.id, result['partner_id']
      end
    end
  end

  context "on PUT to :update" do
    setup do
      @agency_user = Factory(:agency_user)
      @partner = Factory(:partner)
      @partner2 = Factory(:partner)
      PartnerAssignment.create!(:user => @agency_user, :partner => @partner)
    end
    context "with missing params" do
      setup do
        @response = put(:update, :id => 'not_a_partner_id')
      end
      should respond_with(400)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with bad credentials" do
      setup do
        @response = put(:update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => 'foo')
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an invalid id" do
      setup do
        @response = put(:update, :id => 'foo', :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with an id belonging to an invalid partner" do
      setup do
        @currency2 = Factory(:currency)
        @response = put(:update, :id => @partner2.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key)
      end
      should respond_with(403)
      should respond_with_content_type(:json)
      should "respond with error" do
        result = JSON.parse(@response.body)
        assert !result['success']
        assert result['error'].present?
      end
    end
    context "with valid params" do
      setup do
        @response = put(:update, :id => @partner.id, :agency_id => @agency_user.id, :api_key => @agency_user.api_key, :name => 'partner_rename')
      end
      should respond_with(200)
      should respond_with_content_type(:json)
      should "respond with success" do
        result = JSON.parse(@response.body)
        @partner.reload
        assert result['success']
        assert_equal 'partner_rename', @partner.name
      end
    end
  end
end
