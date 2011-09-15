require 'test_helper'

class PointsControllerTest < ActionController::TestCase
  context "on GET to :award" do
    setup do
      @app = Factory(:app)
      @currency = Factory(:currency, :id => @app.id)
      @params = {
        :app_id => @app.id,
        :udid => 'stuff',
        :publisher_user_id => 'me!',
        :tap_points => 10,
        :guid => UUIDTools::UUID.random_create.to_s,
        :timestamp => Time.zone.now
      }
      @params[:verifier] = verifier(@params)
    end

    should 'render error for bad verifier' do
      get :award, @params.merge(:verifier => 'junk')
      assert_template 'error'
      assert_equal 'invalid verifier', assigns(:error_message)
    end

    should 'render error for negative tap points' do
      params = @params.merge(:tap_points => '-1')
      get :award, params.merge(:verifier => verifier(params))
      assert_template 'error'
      assert_equal 'tap_points must be greater than zero', assigns(:error_message)
    end

    should 'award points and render user_account' do
      Sqs.expects(:send_message)
      controller.expects(:check_success).with('award_points')
      Reward.any_instance.expects(:serial_save).with(:catch_exceptions => false, :expected_attr => { 'type' => nil })
      Reward.any_instance.expects(:serialize).with(:attributes_only => true)
      get :award, @params
      assert_template 'user_account'
      assert assigns(:success)
      assert_equal "#{@params[:publisher_user_id]}.#{@params[:app_id]}", assigns(:point_purchases).key
      assert_equal "10 points awarded", assigns(:message)
    end

    should 'not allow re-use of same guid' do
      get :award, @params
      assert_template 'user_account'
      get :award, @params
      assert_template 'error'
      assert_equal 'points already awarded', assigns(:error_message)
    end

    should 'create a reward' do
      get :award, @params.merge(:country => 'US')
      assert_template 'user_account'
      r = Reward.new(:key => @params[:guid], :consistent => true)
      assert !r.new_record?
      assert_equal 'award_currency', r.type
      assert_equal @params[:app_id], r.publisher_app_id
      assert_equal @currency.id, r.currency_id
      assert_equal @params[:publisher_user_id], r.publisher_user_id
      assert_equal @params[:udid], r.udid
      assert_equal 'US', r.country
    end
  end

  context "on GET to :spend" do

  end

  context "on GET to :purchase_vg" do

  end

  context "on GET to :consume_vg" do

  end

private

  def verifier(params)
    Digest::SHA256.hexdigest([
      params[:app_id],
      params[:udid],
      params[:timestamp],
      @app.secret_key,
      params[:tap_points],
      params[:guid],
    ].join(':'))
  end
end
