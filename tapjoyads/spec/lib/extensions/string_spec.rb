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

end
