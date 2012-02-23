require 'spec_helper'

describe PointsController do
  before :each do
    fake_the_web
  end

  describe '#award' do
    before :each do
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
      Sqs.stubs(:send_message)
    end

    it 'renders error for bad verifier' do
      get(:award, @params.merge(:verifier => 'junk'))
      should render_template('layouts/error')
      assigns(:error_message).should == 'invalid verifier'
    end

    it 'renders error for negative tap points' do
      params = @params.merge(:tap_points => '-1')
      get(:award, params.merge(:verifier => verifier(params)))
      should render_template('layouts/error')
      assigns(:error_message).should == 'tap_points must be greater than zero'
    end

    it 'awards points and renders user_account' do
      Sqs.expects(:send_message)
      controller.expects(:check_success).with('award_points')
      Reward.any_instance.expects(:save!).with(:expected_attr => { 'type' => nil })
      get(:award, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_true
      assigns(:point_purchases).key.should == "#{@params[:publisher_user_id]}.#{@params[:app_id]}"
      assigns(:message).should == '10 points awarded'
    end

    it 'does not allow re-use of same guid' do
      get(:award, @params)
      should render_template('get_vg_store_items/user_account')
      get(:award, @params)
      should render_template('layouts/error')
      assigns(:error_message).should == 'points already awarded'
    end

    it 'creates a reward' do
      get(:award, @params.merge(:country => 'US'))
      should render_template('get_vg_store_items/user_account')
      r = Reward.new(:key => @params[:guid], :consistent => true)
      r.new_record?.should be_false
      r.type.should == 'award_currency'
      r.publisher_app_id.should == @params[:app_id]
      r.currency_id.should == @currency.id
      r.publisher_user_id.should == @params[:publisher_user_id]
      r.udid.should == @params[:udid]
      r.country.should == 'US'
    end
  end

  describe '#spend' do
    before :each do
      app = Factory(:app)
      currency = Factory(:currency, :id => app.id)
      @params = {
        :app_id => app.id,
        :udid => 'stuff',
        :tap_points => 10,
      }
    end

    it 'renders points too low message' do
      get(:spend, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_false
      assigns(:point_purchases).should be_nil
      assigns(:message).should == 'Balance too low'
    end

    it 'spends points and renders user_account' do
      p = PointPurchases.new(:key => "#{@params[:udid]}.#{@params[:app_id]}")
      p.points += 100
      p.save!
      controller.expects(:check_success).with('spend_points')
      get(:spend, @params)
      assigns(:success).should be_true
      assigns(:point_purchases).should_not be_nil
      assigns(:message).should == "You successfully spent #{@params[:tap_points]} points"
    end

    it 'spends zero points' do
      get(:spend, @params.merge(:tap_points => '0'))
      assigns(:success).should be_true
      assigns(:point_purchases).should_not be_nil
      assigns(:message).should == ''
    end
  end

  describe '#purchase_vg' do
    before :each do
      app = Factory(:app)
      currency = Factory(:currency, :id => app.id)
      @vg = Factory(:virtual_good)
      @params = {
        :app_id => app.id,
        :udid => 'stuff',
        :virtual_good_id => @vg.key
      }
    end

    it 'purchases vg and renders user_account' do
      p = PointPurchases.new(:key => "#{@params[:udid]}.#{@params[:app_id]}")
      p.points += 100
      p.save!
      controller.expects(:check_success).with('purchased_vg')
      get(:purchase_vg, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_true
      assigns(:point_purchases).should_not be_nil
      assigns(:message).should == "You successfully purchased #{@vg.name}"
    end

    it 'does not purchase if user already has max number of vgs' do
      p = PointPurchases.new(:key => "#{@params[:udid]}.#{@params[:app_id]}")
      p.points += 100
      p.save!
      get(:purchase_vg, @params.merge(:quantity => 6))
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_false
      assigns(:message).should == 'You have already purchased this item the maximum number of times'
    end

    it 'does not purchase if user does not have enough currency' do
      get(:purchase_vg, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_false
      assigns(:message).should == 'Balance too low'
    end
  end

  describe '#consume_vg' do
    before :each do
      app = Factory(:app)
      currency = Factory(:currency, :id => app.id)
      @vg = Factory(:virtual_good)
      @params = {
        :app_id => app.id,
        :udid => 'stuff',
        :virtual_good_id => @vg.key
      }
    end

    it 'consumes one vg' do
      p = PointPurchases.new(:key => "#{@params[:udid]}.#{@params[:app_id]}")
      p.points += 100
      p.save!
      PointPurchases.purchase_virtual_good(p.key, @vg.key, 3)
      controller.expects(:check_success).with('consumed_vg')
      get(:consume_vg, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_true
      assigns(:point_purchases).should_not be_nil
      assigns(:point_purchases).get_virtual_good_quantity(@vg.key).should == 2
      assigns(:message).should == "You successfully used #{@vg.name}"
    end

    it 'consumes more than one vg' do
      p = PointPurchases.new(:key => "#{@params[:udid]}.#{@params[:app_id]}")
      p.points += 100
      p.save!
      PointPurchases.purchase_virtual_good(p.key, @vg.key, 3)
      controller.expects(:check_success).with('consumed_vg')
      get(:consume_vg, @params.merge(:quantity => 2))
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_true
      assigns(:point_purchases).should_not be_nil
      assigns(:point_purchases).get_virtual_good_quantity(@vg.key).should == 1
      assigns(:message).should == "You successfully used #{@vg.name}"
    end

    it "does not consume vg if user doesn't have enough" do
      get(:consume_vg, @params)
      should render_template('get_vg_store_items/user_account')
      assigns(:success).should be_false
      assigns(:message).should == "You don't have enough of this item to do that"
    end

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
