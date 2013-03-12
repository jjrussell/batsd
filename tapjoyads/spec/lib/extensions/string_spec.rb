require 'spec_helper'

describe String do

  context '#matz_silly_hash' do
    before :each do
      @known_values = {
        'amir' => -706469127,
        'tapjoy' => 1527460358,
        'Tapjoy' => -1890408217,
        'California' => 1130092548,
        'a' => 100,
        'A' => 67,
        'f570cd38-6cf5-47c0-9a47-9573020d7c31' => -770717427,
        '0d8d9b90-369b-46da-bdce-da9cda6e52fe' => 350892396,
        '14d64f4d-377d-4877-a970-c73033eeaf85' => -700075254,
        '1f196053-8e40-452b-928c-c9ea2bd17f87' => -1244032130,
        'c9d8090a-8382-4bce-ac65-04e4dd883069' => 41660306,
      }
    end

    it 'returns correct known values' do
      @known_values.each do |k,v|
        k.matz_silly_hash.should == v
      end
    end
  end

  context 'check version methods' do
    before :each do
      @version = "1.2.3"
      @later_version = "1.5.1"
      @earlier_version = "1.1.2"
      @equal_version = "1.2.3"
    end

    it 'creates an array from a string version number' do
      @version.to_version_array.should == [1,2,3]
    end

    it 'checks if version is greater than another version' do
      @version.version_greater_than?(@later_version).should be_false
      @version.version_greater_than?(@earlier_version).should be_true
    end

    it 'checks if version is greater then or equal to another version' do
      @version.version_greater_than_or_equal_to?(@equal_version).should be_true
      @version.version_greater_than_or_equal_to?(@earlier_version).should be_true
      @version.version_greater_than_or_equal_to?(@later_version).should be_false
    end

    it 'checks if version is less than another version' do
      @version.version_less_than?(@later_version).should be_true
      @version.version_less_than?(@earlier_version).should be_false
    end

    it 'checks if version is less then or equal to another version' do
      @version.version_less_than_or_equal_to?(@equal_version).should be_true
      @version.version_less_than_or_equal_to?(@earlier_version).should be_false
      @version.version_less_than_or_equal_to?(@later_version).should be_true
    end

    it 'checks if version is equal to another version' do
      @version.version_equal_to?(@equal_version).should be_true
      @version.version_equal_to?(@earlier_version).should be_false
      @version.version_equal_to?(@later_version).should be_false
    end
  end

  context '#valid_version_string?' do
    it 'returns true for versions with multiple dots' do
      '9.0.0'.should be_valid_version_string
    end

    it 'returns true for version numbers containing more than one digit per position' do
      '10.0.11'.should be_valid_version_string
    end

    it 'returns true for versions without dots' do
      '10'.should be_valid_version_string
    end

    it 'returns false if the string contains any non-digit characters' do
      '10.0.0a'.should_not be_valid_version_string
    end
  end
end
