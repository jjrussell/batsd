module Simpledb
  class DynamicFinderMatch
    attr_reader :finder

    def self.match(method)
      df_match = self.new(method)
      df_match.finder ? df_match : nil
    end

    def initialize(method)
      @finder = :first
      case method.to_s
      when /^find_(all_by|by)_([_a-zA-Z]\w*)$/
        @finder = :all if $1 == 'all_by'
        names = $2
      else
        @finder = nil
      end
      @attribute_names = names && names.split('_and_')
    end

    def attribute_names
      @attribute_names.collect(&:to_s)
    end
  end
end
