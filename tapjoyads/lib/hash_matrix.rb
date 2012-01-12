class HashMatrix
  attr_accessor :rows, :cols

  class HashVector < Hash
    class << self
      def from_pairs pairs
        out = self.new
        pairs.each{ |k, v| out[k] = v }
        out
      end

      def valid?(value)
        value.is_a?(Numeric) && value != 0
      end

    end

    def initialize
      super(0)
    end

    def keys
      super.sort rescue super.sort_by(&:to_s)
    end

    def keys_to_standard_mapping #1,2,3,etc.
      out = {}
      keys.each_with_index{ |k,i| out[k] = i+1 } #one based like octave
      out
    end

    def []=(key, value)
      self.class.valid?(value) ? super : self.delete(key)
    end
    alias_method :store, :[]=

    def *(other, keys = nil)
      case other
      when Hash then times_vector(other, keys)
      when Numeric then times_scalar(other, keys)
      end
    end
    alias_method :times, :*
    alias_method :dot, :*

    def +(other, keys = nil)
      case other
      when Hash then plus_vector(other, keys)
      when Numeric then plus_scalar(other, keys)
      end
    end
    alias_method :plus, :+

    def clone(keys = nil)
      self.class.from_pairs(self.to_pairs(keys))
    end

    def sum
      values.reduce(0){ |t, x| t + x }
    end

    def p_norm(p = 2) #the more general p_norm
      case #optimize computation for common p=1, p=2, p=infinity cases
      when p == 1 then manhattan_norm
      when p == 2 then euclidean_norm
      when p >= 100 then maximum_norm #infinity norm
      when p < 1 then raise "p-norm is only a norm when p>=1"
      else values.reduce(0){ |t, x| t + x.abs**p } ** (1.0/p)
      end
    end

    def p_normalize(p = 2)
      out = self.clone
      out.p_normalize!(p)
      out
    end

    def p_normalize!(p = 2)
      s=p_norm(p)
      keys.each{ |k| self[k] = self[k] * 1.0 / s } if s > 0
    end

    def reindex!(mapping=nil)
      mapping = keys_to_standard_mapping if mapping == nil
      replaced = {}
      self.keys.each{ |k| replace_key!(k, mapping, replaced) unless replaced.has_key?(k) }
    end

    def replace_key!(old_key, mapping, replaced={})
      new_key = mapping[old_key]
      return false unless(new_key && self.has_key?(old_key))
      val = self.delete(old_key)
      if self.has_key?(new_key)
        unless replace_key(new_key, mapping, replaced)
          self[old_key] = val
          return false
        end
      end
      self[new_key] = val
      replaced[old_key] = new_key
      replaced
    end

    def to_pairs(keys = nil)
      keys = keys.nil? ? self.keys : (self.keys & keys.to_a)
      keys.map{ |k| [k, self[k]] }
    end

    def to_s(keys = nil)
      to_pairs(keys).map{ |k, v| "#{k} -> #{v}" }.join("\n")
    end

    private
    def manhattan_norm
      values.reduce(0){ |t, x| t + x.abs } * 1.0
    end

    def euclidean_norm
      Math.sqrt(self * self)
    end

    def maximum_norm
      values.map{ |x| x.abs }.max * 1.0
    end

    def times_vector(other, keys=nil)
      keys = keys.nil? ? (self.keys & other.keys) : (self.keys & other.keys & keys.to_a)
      keys.map{ |i| self[i] * other[i] rescue 0 }.reduce(0){ |t, v| t + v }
    end

    def times_scalar(other, keys=nil)
      self.class.from_pairs(self.to_pairs(keys).map{ |k, v| [k, v*other] })
    end

    def plus_vector(other, keys=nil)
      keys = keys.nil? ? (self.keys | other.keys) : (self.keys | other.keys) & keys.to_a
      self.class.from_pairs keys.map{ |k| [k, self[k] + (other[k] || 0)] }
    end

    def plus_scalar(other, keys=nil)
      self.class.from_pairs(self.to_pairs(keys).map{ |k, v| [k, v + other] })
    end
  end


  class << self
    def from_triplets triplets
      out = self.new
      triplets.each{ |i, j, x| out[i, j] = x }
      out
    end

    def vector
      HashVector #in case we need to change this in subclasses.
    end

    def eye(keys)
      keys = 1..keys if keys.is_a? Numeric
      from_triplets keys.map{ |i| [i, i, 1] }
    end

    def ones(keys)
      keys = 1..keys if keys.is_a? Numeric
      from_triplets keys.map{ |i| keys.map{ |j| [i, j, 1] } }.flatten(1)
    end
  end

  def initialize
    @rows = {}
    @cols = {}
  end

  def row_keys
    @rows.keys.sort rescue @rows.keys.sort_by(&:to_s)
  end

  def col_keys
    @cols.keys.sort rescue @cols.keys.sort_by(&:to_s)
  end

  def rowsum(keys = nil)
    keys = keys.nil? ? self.row_keys : self.row_keys & keys.to_a
    self.class.vector.from_pairs keys.map{ |k| [k, row(k).sum] }
  end

  def colsum(col_keys = nil)
    keys = keys.nil? ? self.col_keys : self.col_keys & keys.to_a
    self.class.vector.from_pairs keys.map{ |k| [k, col(k).sum] }
  end

  def row(i)
    @rows[i] ||= new_vector
  end

  def col(i)
    @cols[i] ||= new_vector
  end

  def [](i, j)
    row(i)[j]
  end

  def []=(i, j, x)
    if self.class.vector.valid?(x)
      row(i)[j] = x
      col(j)[i] = x
    else #don't accumulate keys with empty vectors
      @rows.delete(i) if @rows[i] && @rows[i].empty?
      @cols.delete(j) if @cols[j] && @cols[j].empty?
    end
  end

  def clone(row_keys = nil, col_keys = nil)
    self.class.from_triplets to_triplets(row_keys, col_keys)
  end

  def to_triplets(row_keys = nil, col_keys = nil)
    row_keys = row_keys.nil? ? self.row_keys : self.row_keys & row_keys.to_a
    col_keys = col_keys.nil? ? self.col_keys : self.col_keys & col_keys.to_a
    row_keys.map{ |i| (col_keys & row(i).keys).map{ |j| [i, j, self[i, j]] } }.flatten(1)
  end

  def *(other, keys = nil)
    case other
    when HashMatrix then times_matrix(other, keys)
    when HashVector then times_vector(other, keys)
    when Numeric then times_scalar(other)
    end
  end
  alias_method :times, :*
  alias_method :dot, :*

  def to_s
    to_s_sparse + "\n" + to_s_full(true)
  end

  def to_s_sparse
    to_triplets.map{ |i, j, k| "(#{i}, #{j}) -> #{k}" }.join("\n")
  end

  def to_s_full(labeled = false, row_keys=nil, col_keys=nil)
    row_keys = self.row_keys if row_keys.nil?
    col_keys = self.col_keys if col_keys.nil?
    lines = row_keys.map{ |i| col_keys.map{ |j| self[i,j] }.join("\t") }
    lines = row_keys.zip(lines).map{ |k, l| "[#{k},]\t#{l}" }.unshift((["   "] + col_keys.map{ |k| "[,#{k}]" }).join("\t")) if labeled
    self.compact!
    lines.join("\n")
  end

  def compact!
    @rows.reject!{ |k, v| v.empty? }
    @cols.reject!{ |k, v| v.empty? }
  end

  def reindex_rows(mapping = nil)
    if mapping.nil?
      mapping = {}
      self.row_keys.each_with_index{ |k, i| mapping[k] = i+1 }
    end
    self.row_keys.each{ |k| @rows[mapping[k]] = self.delete(k) }
  end

  protected
  def new_vector
    self.class.vector.new
  end

  private
  def times_vector(other, keys = nil)
    out = new_vector
    @rows.each{ |k, v| out[k] = v.*(other, keys) }
    out
  end

  def times_matrix(other, keys=nil)
    out = self.class.new
    @rows.each{ |sk, sv| other.cols.each{ |ok, ov| out[sk, ok] = sv.*(ov, keys) } }
    # out.compact!
    out
  end

  def times_scalar(other)
    self.class.from_triplets self.to_triplets.map{ |i, j, k| [i, j, k*other] }
  end

end
