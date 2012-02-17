require 'spec_helper'

describe Countries do
  it "should not include North Korea" do
    countries = Countries.contintent_code_to_country_codes.values.flatten
    countries.should_not include('KP')
  end
end
