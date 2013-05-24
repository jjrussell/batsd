require "spec_helper"

shared_examples_for "a successful JSON response" do
  describe "receives a successful HTTP response from the remote host" do
    it "should have a Net::HTTPOK response" do
      subject.response.is_a?(Net::HTTPOK).should be_true
    end
    it "should have a 200 HTTP code" do
      subject.code.should eql(200)
    end
  end
  describe "has appropriate headers" do
    it "with content-type 'application/json'" do
      subject.headers['content-type'].should include("application/json")
    end
  end
end

shared_examples_for "a list of Kontagent resources" do
  it { should be_an Enumerable }
  it "returns a list of hashes" do
    subject.all? { |result| result.is_a? Hash }.should be_true
  end
  context "returns results, each of which" do
    described_class.kontagent_response_fields.map(&:to_s).each do |required_field|
      it "has a #{required_field} key" do
        subject.all? { |result| result.should have_key(required_field) }
      end
    end
  end
end

shared_examples_for "a Kontagent resource" do
  let(:required_fields) { described_class.kontagent_fields.map(&:to_s) }
  around(:each) do |example|
    VCR.use_cassette('kontagent/api', :record => :new_episodes) { example.run }
  end

  context "and support CRUD operations" do
    describe "#create" do
      subject { described_class.create(options.merge(id)) }
      after(:each) do
        @@entity_id = subject["#{described_class.klass}_id"]
      end
      it_should_behave_like 'a successful JSON response'
      described_class.kontagent_response_fields.map(&:to_s).each do |required_field|
        it "should respond with key #{required_field}" do
          subject.parsed_response.should have_key(required_field)
        end
      end
    end

    describe "#read" do
      subject { described_class.read }
      it_should_behave_like 'a successful JSON response'
      it_should_behave_like 'a list of Kontagent resources'
      it "returns a list which includes the newly created resource" do
        matching_resources = subject.parsed_response.select do |element|
          element["#{described_class.klass}_id"] == @@entity_id
        end
        matching_resources.count.should == 1
      end
    end

    describe "#update" do
      let(:updated_fields) { update }
      subject { described_class.update(updated_fields.merge(id)) }
      it_should_behave_like 'a successful JSON response'
      it "responds with appropriately-modified remote resource" do
        update.each do |updated_key, updated_value|
          subject[updated_key.to_s].should == updated_value
        end
      end
    end
  end

  context "and support resourceful operations (#find, #exists?, #build!)" do
    describe "#find" do
      context "by String ID" do
        subject { described_class.find(id.values.first.to_s) }
        it_should_behave_like 'a list of Kontagent resources'
        it "should uniquely identify a single resource" do
          should have(1).item
        end
      end

      context "by Fixnum ID" do
        subject { described_class.find(id.values.first) }
        it_should_behave_like 'a list of Kontagent resources'
        it "should uniquely identify a single resource" do
          should have(1).item
        end
      end

      context "by attributes" do
        subject { described_class.find(query_attrs) }
        it_should_behave_like 'a list of Kontagent resources'
        it "should uniquely identify a single resource" do
          should have(1).item
        end
      end
    end

    describe "#exists?" do
      context "with String-valued ID" do
        subject { described_class.exists?(id.values.first.to_s) }
        it { should be_true }
      end
      context "with Fixnum-valued ID" do
        subject { described_class.exists?(id.values.first) }
        it { should be_true }
      end
      context "with attributes" do
        subject { described_class.exists?(query_attrs) }
        it { should be_true }
      end
    end

    describe "#build!" do
      subject { described_class.build!(options.merge(id)) }
      context "returns an entity which" do
        described_class.kontagent_response_fields.map(&:to_s).each do |required_field|
          it "has a key #{required_field}" do
            subject.should have_key(required_field)
          end
        end
      end
      it "should have a unique (matching) remote identifier" do
        id_key = id.keys.first.to_s
        remote_instance = described_class.find(query_attrs).first
        subject[id_key].should == remote_instance[id_key]
      end
    end
  end
end

describe "managing Kontagent resources" do

  let(:account_identifier) { "543632" }
  let(:user_identifier)    { "343252" }
  let(:app_identifier)     { "432432" }
  let(:title)              { 'a-samplecox' }

  describe Kontagent::Account do
    it_should_behave_like "a Kontagent resource" do
      let(:name) { "#{title}Account" }
      let(:id)      do
        { :account_id => account_identifier }
      end
      let(:options) do
        {
          :name       => name,
          :subdomain  => title
        }
      end
      let(:update) do
        {
           :name => "#{title}AccountUpdated"
        }
      end
      let(:query_attrs) do
        { :name => name }
      end
    end
  end

  describe Kontagent::User do
    it_should_behave_like "a Kontagent resource" do
      let(:username) { "#{title}@some.net" }
      let(:id) do
        { :user_id => user_identifier }
      end
      let(:options) do
        {
          :account_id => account_identifier,
          :first_name => 'John',
          :last_name  => 'Smith',
          :username   => username,
        }
      end
      let(:update) do
        { :username => "#{title}@another.net" }
      end
      let(:query_attrs) do
        { :username => username }
      end
    end
  end

  describe Kontagent::Application do
    it_should_behave_like "a Kontagent resource" do
      let(:name) { "#{title}App" }
      let(:id)      do
        { :application_id => app_identifier }
      end
      let(:options) do
        {
          :account_id     => account_identifier,
          :name           => name,
          :platform_name  => 'iOS'
        }
      end
      let(:update) do
        {
            :name => "#{title}AppUpdated"
        }
      end
      let(:query_attrs) do { :name => name } end
    end
  end

  context "when deleting Kontagent resources" do
    around(:each) do |example|
      VCR.use_cassette('kontagent/api', :record => :new_episodes) { example.run }
    end

    describe "the response code for an Application destruction request" do
      subject { Kontagent::Application.destroy(app_identifier) }
      it { subject.code.should eql(204) } # no content
    end

    describe "the response code for a User destruction request" do
      subject { Kontagent::User.destroy(user_identifier) }
      it { subject.code.should eql(204) } # no content
    end

    describe "the response code for an Account destruction request" do
      subject { Kontagent::Account.destroy(account_identifier) }
      it { subject.code.should eql(204) } # no content
    end
  end

  context "when checking for existence of an inexistent remote resource" do
    around(:each) do |example|
      VCR.use_cassette('kontagent/api', :record => :new_episodes) { example.run }
    end

    describe "an existence check for a missing Application" do
      subject { Kontagent::Application.exists?(-1) }
      it { should be_false }
    end

    describe "an existence check for a missing User" do
      subject { Kontagent::User.exists?(-1) }
      it { should be_false }
    end

    describe "an existence check for a missing Account" do
      subject { Kontagent::Account.exists?(-1) }
      it { should be_false }
    end
  end
end
