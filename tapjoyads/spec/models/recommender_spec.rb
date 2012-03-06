require 'spec_helper'

describe Recommender do
  describe ".instance" do
    context "with an argument" do
      before :all do
        @recommender = Recommender.instance(:most_popular_recommender)
      end

      it "returns an instance of the requested recommender" do
        @recommender.should be_a Recommenders::MostPopularRecommender
      end

      it "returns the same instance on each call" do
        @recommender.should == Recommender.instance(:most_popular_recommender)
      end
    end

    context "without arguments" do
      it "returns an instance of a recommender" do
        Recommender.instance.should be_a Recommender
      end

      it "returns the same instance on each call" do
        Recommender.instance.should == Recommender.instance
      end

      it "returns the recommender set as default" do
        Recommender.instance.class.name.should == "Recommenders::#{Recommender::DEFAULT_RECOMMENDER.to_s.camelize}"
      end
    end
  end

  describe ".type" do
    it "returns a symbol" do
      Recommender.type.should be_a Symbol
    end
  end

  describe ".is_active?" do
    context "when called with type of base class" do
      it "is not active" do
        Recommender.is_active?(Recommender.type).should be false
      end
    end

    context "when called with type of default instance" do
      it "is active" do
        Recommender.is_active?(Recommender.instance.type).should be true
      end
    end
  end
end


def recommender_instance_spec(recommender)
  describe recommender.class do
    before :each do
      fake_the_web
      recommender.cache_all
      @app = "003333af-df6f-4a03-80dd-082e35237d12"
      @udid = "statz_test_udid"
    end

    describe "cache_all" do
      it "reads information from files, parses it correctly, and puts it in the cache ready to use" do
        recommender.most_popular.present?.should be true
        recommender.for_app(@app).present?.should be true
        recommender.for_device(@udid).present?.should be true
      end
    end

    describe "#for_app" do
      context "given an app id and no parameters" do
        it "returns an array" do
          recommender.for_app(@app).should be_an Array
        end

        it "returns an array composed of pairs" do
          recommender.for_app(@app).first.should be_an Array
          recommender.for_app(@app).first.length.should == 2
        end

        it "returns an array of pairs of the form [String, Numeric]" do
          recommender.for_app(@app).first.first.should be_a String
          recommender.for_app(@app).first.last.should be_a Numeric
        end
      end

      context "given an app id and parameters" do
        it "limits the results to n when parameter n is given" do
          recommender.for_app(@app, :n => 5).should have_at_most(5).items
        end
      end
    end

    describe "#for_device" do
      context "given a device and no parameters" do
        it "returns an array" do
          recommender.for_device(@udid).should be_an Array
        end

        it "returns an array composed of pairs" do
          recommender.for_device(@udid).first.should be_an Array
          recommender.for_device(@udid).first.length.should == 2
        end

        it "returns an array of pairs of the form [String, Numeric]" do
          recommender.for_device(@udid).first.first.should be_a String
          recommender.for_device(@udid).first.last.should be_a Numeric
        end
      end

      context "given a device id and parameters" do
        it "limits the results to n when parameter n is given" do
          recommender.for_device(@udid, :n=>2).should have_at_most(2).items
        end
      end
    end

    describe "#most_popular" do
      context "given no parameters" do
        it "returns an array" do
          recommender.most_popular.should be_an Array
        end

        it "returns an array composed of pairs" do
          recommender.most_popular.first.should be_an Array
          recommender.most_popular.first.length.should == 2
        end

        it "returns an array of pairs of the form [String, Numeric]" do
          recommender.most_popular.first.first.should be_a String
          recommender.most_popular.first.last.should be_a Numeric
        end
      end

      context "given parameters" do
        it "limits the results to n when parameter n is given" do
          recommender.most_popular(:n => 3).should have_at_most(3).items
        end
      end
    end
  end
end

Recommender::ACTIVE_RECOMMENDERS.keys.map do |rec_type|
  recommender_instance_spec(Recommender.instance(rec_type))
end
