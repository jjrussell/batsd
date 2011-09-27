GAMES_YAML_CONFIG = "config/games.yaml"
GAMES_JS_DIR = "public/javascripts/games"
GAMES_JS_SRC_DIR = "public/javascripts/games/src"
GAMES_JS_CAT_DIR = "public/javascripts/games/src/target"
GAMES_JS_CAT_FILE = 'tjgames.js'
COMPILER_JAR_PATH = "vendor/plugins/yuicompressor/yuicompressor-2.4.6.jar" 
JS_EXT = '.js'

namespace :javascript do
  
  desc "Tapjoy Games - Compile and minify JavaScript files"
  task :games_minify do
    config = YAML::load_file(GAMES_YAML_CONFIG)['production']
    files = config['js_files']
    version = config['js_version']
    compile_out_file = config['js_compile_out_file']
    File.open("#{GAMES_JS_CAT_DIR}/#{GAMES_JS_CAT_FILE}","w+") do |f|
      concat = files.map do |j|
        c = "#{GAMES_JS_SRC_DIR}/#{j}#{JS_EXT}"
        IO.read(c)
      end
      f.puts concat
    end
    
    system "java -jar #{COMPILER_JAR_PATH} #{GAMES_JS_CAT_DIR}/#{GAMES_JS_CAT_FILE} --type js -o #{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}"
    if File.exist?("#{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}")
      puts "File successfully compiled at:"
      puts File.ctime("#{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}")
      puts "File location:"
      puts "#{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}"
    else
      puts "Compilation Failed"
    end
  end
  
end
