require 'spec_helper'

describe FormatChecks do

  context '#uuid?' do
    it 'correctly identifies uuids' do
      "93e75426-6851-403c-a9e4-488bffeb6f12".uuid?.should be_true
      "7194816d-06e1-472b-9577-df47d8c6180f".uuid?.should be_true
      "945c343a-6a5b-4495-af7f-cac9efb74605".uuid?.should be_true
      "93e75426-6851-403c-a9e4-488gffeb6f12".uuid?.should be_false
      "7194816d06e1472b9577df47d8c6180f".uuid?.should be_false
      "945c343a-6a5b-4495-af7f-cac9efb74605-1asdf".uuid?.should be_false
      "93E75426-6851-403c-a9e4-488gffeb6f12".uuid?.should be_false
    end

    it 'returns false for nil' do
      nil.uuid?.should be_false
    end
  end

  context '#udid?' do
    it 'correctly identifies udids' do
      "eb25d9b88f5238051ae7600197760e52ce6e8453".udid?.should be_true
      "ade749ccc744336ad81cbcdbf36a5720778c6f13".udid?.should be_true
      "0a06b4187777522094f42d039a665c8a58f0d733".udid?.should be_true
      "eb25d9b88f5238051le7600197760e52ce6e8453".udid?.should be_false
      "ade749ccc-7443-36ad-81cb-cdbf36a5720778c6f13".udid?.should be_false
      "0a06b4187777522094f42d039A665c8a58f0d733".udid?.should be_false
    end

    it 'returns false for nil' do
      nil.udid?.should be_false
    end
  end

end
