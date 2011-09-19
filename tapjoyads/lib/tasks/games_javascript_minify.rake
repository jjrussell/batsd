YAML_CONFIG = "config/games.yaml"
JS_DIR = "public/javascripts/games"
JS_SRC_DIR = "public/javascripts/games/src"
JS_CAT_DIR = "public/javascripts/games/src/target"
JS_CAT_FILE = 'tjgames.js'
COMPILER_JAR_PATH = "vendor/plugins/yuicompressor/yuicompressor-2.4.6.jar" 
EXT = '.js'

namespace :javascript do
  
  desc "Tapjoy Games - Compile and minify JavaScript files"
  task :games_minify do
    require 'yaml'
    @config = YAML::load(File.open(YAML_CONFIG))['production']
    files = @config['js_files']
    version = @config['js_version']
    compile_out_file = @config['js_compile_out_file']
    File.open("#{JS_CAT_DIR}/#{JS_CAT_FILE}","w+") { |f|
      f.puts files.map{ |j|
        c = "#{JS_SRC_DIR}/" << j << "#{EXT}"
        IO.read(c)
      } 
    }
    
    system "java -jar #{COMPILER_JAR_PATH} #{JS_CAT_DIR}/#{JS_CAT_FILE} --type js -o #{JS_DIR}/#{compile_out_file}-#{version}#{EXT}"
    if File.exist?("#{JS_DIR}/#{compile_out_file}-#{version}#{EXT}")
      print "\n\tFile successfully compiled at: "
      print File.ctime("#{JS_DIR}/#{compile_out_file}-#{version}#{EXT}")
      print "\n\tFile location: "
      print "#{JS_DIR}/#{compile_out_file}-#{version}#{EXT}"
      print "\n\n"
    else
      print "\n\tCompilation Failed\n\n"
    end
  end
  
end
