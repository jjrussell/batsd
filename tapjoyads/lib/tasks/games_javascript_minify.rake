YAML_CONFIG = "config/javascript-games.yaml"
JS_DIR = "public/javascripts/games"
JS_SRC_DIR = "public/javascripts/games/src"
JS_COMPILE_DIR = "public/javascripts/games/src/target"
JS_COMPILE_FILE = 'tjgames.js'
COMPILER_JAR_PATH = "vendor/plugins/yuicompressor/yuicompressor-2.4.6.jar" 
COMPILER_OUT_FILE = 'tjgames.min'
EXT = '.js'

namespace :javascript do

  desc "Tapjoy Games - Compile and minify JavaScript files"
  task :games_minify do
    require 'yaml'
    @config = YAML::load(File.open(YAML_CONFIG))
    files = @config['files']
    version = @config['version']
    File.open("#{JS_COMPILE_DIR}/#{JS_COMPILE_FILE}","w+") { |f|
      f.puts files.map{ |j|
        c = "#{JS_SRC_DIR}/" << j << "#{EXT}"
        IO.read(c)
      } 
    }
    
    system "java -jar #{COMPILER_JAR_PATH} #{JS_COMPILE_DIR}/#{JS_COMPILE_FILE} --type js -o #{JS_DIR}/#{COMPILER_OUT_FILE}-#{version}#{EXT}"

  end
  
end