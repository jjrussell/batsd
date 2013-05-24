#Remove this after migration to 1.9.3
unless Hash.new.respond_to? :key
  class Hash
    alias_method :key, :index
  end
end
