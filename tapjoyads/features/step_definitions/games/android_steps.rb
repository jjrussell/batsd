Given /^I visited the android page with a valid device and app$/ do
  app = Factory.create(:app)
  udid = 'testudid'

  # generate the verifier
  verifier_hash_bits = [ app.id, udid, nil, app.secret_key ]
  verifier = Digest::SHA256.hexdigest(verifier_hash_bits.join(':'))

  visit "/games/android?verifier=#{verifier}&udid=#{udid}&app_id=#{app.id}"
end
