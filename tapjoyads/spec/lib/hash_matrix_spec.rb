require 'spec_helper'


describe HashMatrix do
  before do
    @matrix = HashMatrix.eye(3)
    @matrix[1, 3] = 1
    @matrix[3, 1] = -1
    @matrix[6, 6] = 1
    @vector = HashMatrix.vector.from_pairs [[1,2], [2,-2], [3,4], [6,-5]]
  end

  describe "different string representations" do
    it "should return sparse matrix representation" do
      @matrix.to_s_sparse.should == <<-STR.gsub(/^\s*/, '').strip
      (1, 1) -> 1
      (1, 3) -> 1
      (2, 2) -> 1
      (3, 1) -> -1
      (3, 3) -> 1
      (6, 6) -> 1
      STR
    end
    it "should return matrix in full mode without labels" do
      @matrix.to_s_full.should == <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
      1 0 1 0
      0 1 0 0
      -1  0 1 0
      0 0 0 1
      STR
      puts "print matrix in full mode with labels"
      puts @matrix.to_s_full true
      idx = (1..8)
      puts "print matrix in full mode with labels for indices #{idx.to_a.inspect}"
      puts @matrix.to_s_full true, idx, idx
      puts "print matrix default:"
      puts @matrix
    end
  end

  it "should find the p-norms of a vector, and normalize it correctly for different ps" do
    puts "P_norms for vector \n#{@vector}"
    [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000].each{ |p| puts "p_norm(#{p}) = #{@vector.p_norm(p)}" }
    @vector.p_norm(1).should == 13
    @vector.p_norm(2).should == 7
    @vector.p_norm(3).should be_close 5.896, 0.001
    @vector.p_norm(1000).should == 5
    lambda{@vector.p_norm(0.5)}.should raise_error
    [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000].each{ |p| puts "normalize for p = #{p}"; puts @vector.p_normalize(p); puts "dot product:"; puts(@vector.p_normalize(p) * @vector.p_normalize(p)) }
    puts "dot product with itself:"
    puts @vector*@vector
    puts (@vector.p_normalize(2) * @vector.p_normalize(2))
    (@vector*@vector).should == 49
    (@vector.p_normalize(2) * @vector.p_normalize(2)).should == 1
  end

  it "should projection and print with a subset of keys instead of all its keys" do
    puts "vector"
    puts @vector.to_s
    puts "vector 1..2"
    puts @vector.to_s 1..2
    @matrix[7, 1]=20
    puts "matrix"
    puts @matrix
    puts "triplets"
    p @matrix.to_triplets
    puts "triplets 1..2, 1..3"
    p @matrix.to_triplets 1..2, 1..3
    puts "matrix projection 1..2, 1..3"
    puts @matrix.projection 1..2, 1..3
    puts "matrix projection nil, 1..3"
    puts @matrix.projection nil, 1..3
    puts "matrix projection 1..2, nil"
    puts @matrix.projection 1..2, nil
    puts "matrix projection nil, 1..1"
    puts @matrix.projection nil, 1..1
  end

  it "should do matrix * vector and matrix * matrix multiplication, and also do it with a subset of the keys" do
    (@matrix * @matrix).should be_a HashMatrix
    (@matrix * @vector).should be_a HashMatrix.vector
    puts "matrix"
    puts @matrix
    puts "vector"
    puts @vector
    puts "matrix * vector"
    puts @matrix * @vector
    puts "matrix * vector 1..2"
    puts @matrix.*(@vector, 1..2)
    puts "matrix * vector 1..1"
    puts @matrix.*(@vector, 1..1)
    puts "matrix * matrix"
    puts @matrix * @matrix
    puts "matrix * matrix 1..2"
    puts @matrix.*(@matrix, 1..2)
    puts "matrix * matrix 1..1"
    puts @matrix.*(@matrix, 1..1)
    m=HashMatrix.from_triplets [[:a,1,1], [2,:b,2], [1,:c,3]]
    m[1,2] = -1
    puts m
    idx = [1,2,3,4,5, :a, :b, :c]
    puts m.to_s_full(true, idx, idx)
    puts m*m
    p idx
    puts (m*m).to_s_full(true, idx, idx)
    puts m*@vector
    puts @vector * {:a => 3, 2 => :a, 3 => 4}
  end

  it "should only store non-zero values" do
    l1 = @vector.length
    @vector[100] = 12
    l2= @vector.length
    l2.should == (l1 + 1)
    @vector[200] = 0
    l3 = @vector.length
    l3.should == l2
  end
end
