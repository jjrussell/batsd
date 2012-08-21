Dir[File.dirname(__FILE__) + '/one_offs/*.rb'].each { |file| require(file) }

class OneOffs
end
