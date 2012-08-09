require 'spec_helper'

describe AppMetadataMapping do
  it { should belong_to :app }
  it { should belong_to :app_metadata }

  it { should validate_presence_of :app }
  it { should validate_presence_of :app_metadata }

  describe '#has_conflicting_primary_metadata?' do
    before :each do
      @app = FactoryGirl.create(:app)
    end

    context 'as the only app metadata mapping' do
      it 'is false' do
        @app.primary_app_metadata_mapping.should_not have_conflicting_primary_metadata
      end
    end

    context 'with another metadata' do
      before :each do
        @new_mapping = @app.app_metadata_mapping.build
      end

      context ' that is not primary' do
        it 'is false' do
          new_mapping.should_not have_conflicting_primary_metadata
        end
      end

      context 'with another metadata that is primary' do
        it 'is true' do
          new_mapping.is_primary = true
          new_mapping.should have_conflicting_primary_metadata
        end
      end
    end

  end
end
