module TypeConverters

  class StringConverter
    def from_string(s)
      s
    end
    def to_string(s)
      s.to_s
    end
  end

  class IntConverter
    def from_string(s)
      s.to_i
    end
    def to_string(i)
      i.to_s
    end
  end

  class FloatConverter
    def from_string(s)
      s.to_f
    end
    def to_string(f)
      f.to_s
    end
  end

  class TimeConverter
    def from_string(s)
      Time.zone.at(s.to_f)
    end
    def to_string(t)
      t.to_f.to_s
    end
  end

  class BoolConverter
    def from_string(s)
      s == '1' || s == 'True'
    end
    def to_string(b)
      b ? '1' : '0'
    end
  end

  class JsonConverter
    def from_string(s)
      JSON.parse(s)
    end
    def to_string(j)
      j.to_json
    end
  end

  TYPES = {
    :string => StringConverter.new,
    :int    => IntConverter.new,
    :float  => FloatConverter.new,
    :time   => TimeConverter.new,
    :bool   => BoolConverter.new,
    :json   => JsonConverter.new,
  }

end
