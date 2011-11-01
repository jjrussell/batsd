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
    
    concat = files.map do |j|
      c = "#{GAMES_JS_SRC_DIR}/#{j}#{JS_EXT}"
      t = IO.read(c)
      if t.match(/console.log\(|alert\(/)
        abort("\nERROR: console.log() or alert() commands found in: #{c}. Please remove and try again. \n\n")
      end
      t
    end
    
    File.open("#{GAMES_JS_CAT_DIR}/#{GAMES_JS_CAT_FILE}","w+") do |f|
      f.puts concat
    end
    
    system "java -jar #{COMPILER_JAR_PATH} #{GAMES_JS_CAT_DIR}/#{GAMES_JS_CAT_FILE} --type js -o #{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}"
    if File.exist?("#{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}")
      puts "\nSUCCESS: File compiled at:"
      puts File.ctime("#{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}")
      puts "File location: #{GAMES_JS_DIR}/#{compile_out_file}-#{version}#{JS_EXT}\n\n"
    else
      puts "\nERROR: Compilation Failed\n\n"
    end
  end

end
