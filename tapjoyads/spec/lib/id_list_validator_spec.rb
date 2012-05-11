require 'spec_helper'

describe IdListValidator do

  class ValidationTarget
    include ActiveModel::Validations
    attr_accessor :app_ids, :nilable_app_ids, :blankable_app_ids
    validates :app_ids, :id_list => { :of => App }
    validates :nilable_app_ids, :id_list => { :of => App }, :allow_nil => true
    validates :blankable_app_ids, :id_list => { :of => App }, :allow_blank => true
  end

  subject { ValidationTarget.new }

  context 'considering nils - ' do
    it 'allows nils when :allow_nil configured' do
      App.stubs(:find_by_id).returns(true)
      subject.app_ids = '12345'
      subject.nilable_app_ids = nil
      subject.blankable_app_ids = ''
      subject.should be_valid
    end

    it 'rejects nils when :allow_nil not given' do
      subject.app_ids = nil
      subject.should_not be_valid
      subject.errors[:app_ids].should_not == []
    end
  end

  context 'considering blanks - ' do
    it 'allows blanks when :allow_blank configured' do
      App.stubs(:find_by_id).returns(true)
      subject.app_ids = '12345'
      subject.blankable_app_ids = ''
      subject.should be_valid
    end

    it 'rejects blanks when :allow_blank not given' do
      subject.app_ids = ''
      subject.should_not be_valid
      subject.errors[:app_ids].should_not == []
    end
  end

  it 'rejects invalid id values' do
    App.stubs(:find_by_id).with('12345').returns(true)
    App.stubs(:find_by_id).with('45678').returns(nil)
    subject.app_ids = '12345;45678'
    subject.should_not be_valid
    subject.errors[:app_ids].should_not == []
  end

  context 'with happiness and rainbows' do
    before :each do
      App.stubs(:find_by_id).with('12345').returns(true)
      App.stubs(:find_by_id).with('45678').returns(true)
    end

    it 'validates' do
      subject.app_ids = '12345;45678'
      subject.should be_valid
    end
  end

  context 'on an ActiveRecord object' do
    class DirtyValidationTarget
      include ActiveModel::Validations
      include ActiveModel::Dirty
      define_attribute_methods [:user_ids]
      validates :user_ids, :id_list => { :of => User }

      def user_ids
        @user_ids
      end

      def user_ids=(val)
        user_ids_will_change!
        @user_ids = val
      end

      def save
        @changed_attributes.clear
      end
    end

    it 'only applies validation to dirty fields' do
      obj = DirtyValidationTarget.new
      obj.user_ids = '12345;6789'
      obj.save
      App.stubs(:find_by_id).never
      obj.should be_valid
    end
  end
end
