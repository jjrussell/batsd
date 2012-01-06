Dir[File.dirname(__FILE__) + '/simpledb/*.rb'].each { |file| require(file) }

module Simpledb
  def self.included(base)
    base.send :include, Simpledb::FindMethods
  end
end