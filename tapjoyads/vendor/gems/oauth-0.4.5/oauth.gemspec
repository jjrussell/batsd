# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{oauth}
  s.version = "0.4.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pelle Braendgaard", "Blaine Cook", "Larry Halff", "Jesse Clark", "Jon Crosby", "Seth Fitzsimmons", "Matt Sanford", "Aaron Quint"]
  s.date = %q{2011-06-25}
  s.default_executable = %q{oauth}
  s.description = %q{OAuth Core Ruby implementation}
  s.email = %q{oauth-ruby@googlegroups.com}
  s.executables = ["oauth"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc",
    "TODO"
  ]
  s.files = [
    ".gemtest",
    "Gemfile",
    "Gemfile.lock",
    "HISTORY",
    "LICENSE",
    "README.rdoc",
    "Rakefile",
    "TODO",
    "bin/oauth",
    "examples/yql.rb",
    "lib/digest/hmac.rb",
    "lib/oauth.rb",
    "lib/oauth/cli.rb",
    "lib/oauth/client.rb",
    "lib/oauth/client/action_controller_request.rb",
    "lib/oauth/client/em_http.rb",
    "lib/oauth/client/helper.rb",
    "lib/oauth/client/net_http.rb",
    "lib/oauth/consumer.rb",
    "lib/oauth/core_ext.rb",
    "lib/oauth/errors.rb",
    "lib/oauth/errors/error.rb",
    "lib/oauth/errors/problem.rb",
    "lib/oauth/errors/unauthorized.rb",
    "lib/oauth/helper.rb",
    "lib/oauth/oauth.rb",
    "lib/oauth/oauth_test_helper.rb",
    "lib/oauth/request_proxy.rb",
    "lib/oauth/request_proxy/action_controller_request.rb",
    "lib/oauth/request_proxy/base.rb",
    "lib/oauth/request_proxy/curb_request.rb",
    "lib/oauth/request_proxy/em_http_request.rb",
    "lib/oauth/request_proxy/jabber_request.rb",
    "lib/oauth/request_proxy/mock_request.rb",
    "lib/oauth/request_proxy/net_http.rb",
    "lib/oauth/request_proxy/rack_request.rb",
    "lib/oauth/request_proxy/typhoeus_request.rb",
    "lib/oauth/server.rb",
    "lib/oauth/signature.rb",
    "lib/oauth/signature/base.rb",
    "lib/oauth/signature/hmac/base.rb",
    "lib/oauth/signature/hmac/md5.rb",
    "lib/oauth/signature/hmac/rmd160.rb",
    "lib/oauth/signature/hmac/sha1.rb",
    "lib/oauth/signature/hmac/sha2.rb",
    "lib/oauth/signature/md5.rb",
    "lib/oauth/signature/plaintext.rb",
    "lib/oauth/signature/rsa/sha1.rb",
    "lib/oauth/signature/sha1.rb",
    "lib/oauth/token.rb",
    "lib/oauth/tokens/access_token.rb",
    "lib/oauth/tokens/consumer_token.rb",
    "lib/oauth/tokens/request_token.rb",
    "lib/oauth/tokens/server_token.rb",
    "lib/oauth/tokens/token.rb",
    "oauth.gemspec",
    "tasks/deployment.rake",
    "tasks/environment.rake",
    "tasks/website.rake",
    "test/cases/oauth_case.rb",
    "test/cases/spec/1_0-final/test_construct_request_url.rb",
    "test/cases/spec/1_0-final/test_normalize_request_parameters.rb",
    "test/cases/spec/1_0-final/test_parameter_encodings.rb",
    "test/cases/spec/1_0-final/test_signature_base_strings.rb",
    "test/integration/consumer_test.rb",
    "test/keys/rsa.cert",
    "test/keys/rsa.pem",
    "test/test_access_token.rb",
    "test/test_action_controller_request_proxy.rb",
    "test/test_consumer.rb",
    "test/test_curb_request_proxy.rb",
    "test/test_em_http_client.rb",
    "test/test_em_http_request_proxy.rb",
    "test/test_helper.rb",
    "test/test_hmac_sha1.rb",
    "test/test_net_http_client.rb",
    "test/test_net_http_request_proxy.rb",
    "test/test_oauth_helper.rb",
    "test/test_rack_request_proxy.rb",
    "test/test_request_token.rb",
    "test/test_rsa_sha1.rb",
    "test/test_server.rb",
    "test/test_signature.rb",
    "test/test_signature_base.rb",
    "test/test_signature_plain_text.rb",
    "test/test_token.rb",
    "test/test_typhoeus_request_proxy.rb"
  ]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{oauth}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{OAuth Core Ruby implementation}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, [">= 0"])
      s.add_development_dependency(%q<actionpack>, [">= 2.3.5"])
      s.add_development_dependency(%q<rack>, [">= 1.0.0"])
      s.add_development_dependency(%q<mocha>, [">= 0.9.8"])
      s.add_development_dependency(%q<typhoeus>, [">= 0.1.13"])
      s.add_development_dependency(%q<em-http-request>, [">= 0.2.10"])
      s.add_development_dependency(%q<curb>, [">= 0.6.6.0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<jeweler>, [">= 0"])
      s.add_dependency(%q<actionpack>, [">= 2.3.5"])
      s.add_dependency(%q<rack>, [">= 1.0.0"])
      s.add_dependency(%q<mocha>, [">= 0.9.8"])
      s.add_dependency(%q<typhoeus>, [">= 0.1.13"])
      s.add_dependency(%q<em-http-request>, [">= 0.2.10"])
      s.add_dependency(%q<curb>, [">= 0.6.6.0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<jeweler>, [">= 0"])
    s.add_dependency(%q<actionpack>, [">= 2.3.5"])
    s.add_dependency(%q<rack>, [">= 1.0.0"])
    s.add_dependency(%q<mocha>, [">= 0.9.8"])
    s.add_dependency(%q<typhoeus>, [">= 0.1.13"])
    s.add_dependency(%q<em-http-request>, [">= 0.2.10"])
    s.add_dependency(%q<curb>, [">= 0.6.6.0"])
  end
end

