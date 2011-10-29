require 'test_helper'

class Games::GamersControllerTest < ActionController::TestCase
  setup :activate_authlogic

  context "creating new gamer" do
    should "return json with no errors" do
      params = {
        :gamer => {
          :email            => Factory.next(:email),
          :password         => Factory.next(:name),
          :terms_of_service => '1',
        },
        :date => {
          :year   => '1981',
          :month  => '10',
          :day    => '23',
        },
      }

      post 'create', params

      assert_response(200)
      json = JSON.load(@response.body)
      assert_equal true, json['success']
    end

    should "return error json if too young" do
      params = {
        :gamer => {
          :email            => Factory.next(:email),
          :password         => Factory.next(:name),
          :terms_of_service => '1',
        },
        :date => {
          :year   => Date.today.year,
          :month  => '10',
          :day    => '23',
        },
      }

      post 'create', params

      assert_response(200)
      json = JSON.load(@response.body)
      assert_equal false, json['success']
      assert_equal 1, json['error'].length
    end
  end

  context "deactivating gamer" do
    should "mark gamer as deactivated" do
      params = {
        :gamer => {
          :email            => Factory.next(:email),
          :password         => Factory.next(:name),
          :terms_of_service => '1',
        },
        :date => {
          :year   => '1981',
          :month  => '10',
          :day    => '23',
        },
      }

      post 'create', params
      assert_not_nil assigns(:gamer)
      gamer = assigns(:gamer)

      post 'destroy'
      assert_redirected_to(games_logout_path)
      assert_not_nil gamer.reload.deactivated_at
    end
  end
end
