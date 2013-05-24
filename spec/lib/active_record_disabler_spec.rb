require 'spec_helper'

describe ActiveRecordDisabler do
  before(:each) do
    @app_id = Factory(:app).id
    Rails.env.stub(:development?) { true }
    ActiveRecordDisabler.disable_queries!
  end

  let(:procs_that_query) do
    [].tap do |procs|
      procs << Proc.new { App.find(@app_id) }
      procs << Proc.new { App.where(:id => @app_id).all }
      procs << Proc.new { Factory(:app) }
    end
  end

  let(:procs_that_dont) do
    [].tap do |procs|
      procs << Proc.new { App.find_in_cache(@app_id).id.should == @app_id  }
      procs << Proc.new { Currency.find_all_in_cache_by_app_id(@app_id) }
      procs << Proc.new { ReengagementOffer.find_all_in_cache_by_app_id(@app_id) }
    end
  end

  describe 'with queries disabled' do
    it 'causes AR select/insert/update to raise QueriesDisabled' do
      procs_that_query.each do |proc_should_raise|
        expect { proc_should_raise.call }.to raise_exception(ActiveRecordDisabler::QueriesDisabled)
      end
    end
  end

  describe '.with_queries_enabled' do
    it 'allows AR queries inside a provided block' do
      ActiveRecordDisabler.with_queries_enabled do
        procs_that_query.each do |proc_should_not_raise|
          expect { proc_should_not_raise.call }.to_not raise_exception
        end
      end

      # Sanity check
      expect { procs_that_query.first.call }.to raise_exception(ActiveRecordDisabler::QueriesDisabled)
    end

    it 'allows nested calls' do
      ActiveRecordDisabler.with_queries_enabled do
        ActiveRecordDisabler.with_queries_enabled do
          expect { procs_that_query.first.call }.to_not raise_exception
        end

        expect { procs_that_query.first.call }.to_not raise_exception
      end

      expect { procs_that_query.first.call }.to raise_exception(ActiveRecordDisabler::QueriesDisabled)
    end
  end
end
