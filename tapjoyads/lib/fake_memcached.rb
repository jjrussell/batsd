require 'memcached'
class FakeMemcached
  attr_accessor :data
  def initialize
    @data = {}
  end
  def get(key)
    raise Memcached::NotFound.new  unless @data.key?(key)
    @data[key]
  end
  def set(key, value)
    @data[key]=value
    nil
  end
  #def get_multi(*keys)  Not supported
  #  keys.map{|key| @data[key]}
  #end
  def delete(key)
    raise Memcached::NotFound.new  unless @data.key?(key)
    @data.delete
  end
end