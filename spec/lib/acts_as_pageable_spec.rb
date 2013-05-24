require 'spec_helper'

describe ActsAsPageable do
  include ActsAsPageable

  let(:sample_resource_name) { :sample_resource_name }
  let(:sample_action_name) { :index }
  subject do
    k = Class.new
    k.stub(:before_filter).and_return(true)
    k.send(:include, described_class)
    k
  end

  describe '.pageable_resource' do
    it 'requires a resource' do
      expect{self.class.pageable_resource()}.to raise_error(ArgumentError)
    end

    it 'sets a before filter, :page_results' do
      self.class.should_receive(:before_filter).with(:page_results)
      self.class.pageable_resource(sample_resource_name, :only => sample_action_name)
    end

    context 'given a suitable including class' do
      it 'requires an :only option' do
        expect {
          subject.pageable_resource sample_resource_name, :start_page => 1
        }.to raise_error{PageableActionRequiredException}
      end

      it 'accepts an :only option as a Symbol' do
        expect {
          subject.pageable_resource sample_resource_name, :only => sample_action_name
        }.not_to raise_error
      end

      it 'accepts an :only option as an Array of Symbols' do
        expect {
          subject.pageable_resource sample_resource_name, :only => [sample_action_name]
        }.not_to raise_error
      end

      it 'accepts a :start_page option' do
        expect {
          subject.pageable_resource sample_resource_name, :only => [sample_action_name], :start_page => 1
        }.not_to raise_error
      end

      it 'accepts a :per_page option' do
        expect {
          subject.pageable_resource sample_resource_name, :only => [sample_action_name], :per_page => 1
        }.not_to raise_error
      end
    end
  end

  describe '#page_results' do
    it 'requires a #resource that responds to #paginate' do
      subject.pageable_resource sample_resource_name, :only => sample_action_name
      subject.stub(:resource).and_return(nil)
      expect{subject.page_results}.to raise_error(NoMethodError)
    end
  end

  describe '.valid_action?' do
    context 'given an action that was specified with the :only option of #pageable_resource' do
      before(:each) { subject.pageable_resource sample_resource_name, :only => [sample_action_name] }
      it 'is true' do
        subject.valid_action?(sample_action_name).should be_true
      end
    end

    context 'given an action that was not specified with the :only option of #pageable_resource' do
      let(:another_action_name) { :another_action_name }
      before(:each) { subject.pageable_resource sample_resource_name, :only => [sample_action_name] }
      it 'is false' do
        subject.valid_action?(another_action_name).should be_false
      end
    end
  end

  describe '.invalid_action?' do
    it 'is the opposite of .valid_action?' do
      self.class.stub(:valid_action?).and_return(true)
      self.class.invalid_action?(sample_action_name).should be_false
    end
  end

  context 'given a pageable resource has been defined' do
    def self.before_filter(*params); end
    before(:each) do
      self.class.pageable_resource :sample_resource, :only => sample_action_name
    end

    describe '.paging_options' do
      OPTIONS = [:current_page, :per_page]

      subject { self.class.paging_options }
      OPTIONS.each do |o|
        it "has a key ':#{o}'" do
          subject.should have_key o
        end
      end

      describe '[:current_page]' do
        subject { self.class.paging_options[:current_page] }
        it 'is 1 by default' do
          subject.should == 1
        end
      end

      describe '[:per_page]' do
        subject { self.class.paging_options[:per_page] }
        it 'is 30 by default' do
          subject.should == 30
        end
      end
    end

  end

end
