require 'static_compiler'

class Sprockets::Environment
  attr_accessor :digest_list
  @digest_list = {}
end
ASSETS = Sprockets::Environment.new

ASSETS.append_path 'app/assets/javascripts'
ASSETS.append_path 'app/assets/stylesheets'
ASSETS_PATH = "#{Rails.root}/public/assets/"

compiler = Sprockets::Joy::StaticCompiler.new(ASSETS, ASSETS_PATH, {:digest => true})
compiler.compile

if File.exists?("#{ASSETS_PATH}asset_manifest.yml")
  ASSETS.digest_list = YAML::load_file("#{ASSETS_PATH}asset_manifest.yml")
end
