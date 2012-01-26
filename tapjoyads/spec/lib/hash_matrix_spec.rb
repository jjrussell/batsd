require 'spec_helper'

describe HashMatrix do
  before do
    @m = HashMatrix.eye(3)
    @m[1, 3] = 1
    @m[3, 1] = -1
    @m[6, 6] = 1
    @v = HashMatrix.vector.from_pairs [[1,2], [2,-2], [3,4], [6,-5]]
  end

  it "should print and not fail with a few different options" do
    puts "print matrix in sparse mode"
    puts @m.to_s_sparse
    puts "print matrix in full mode without labels"
    puts @m.to_s_full
    puts "print matrix in full mode with labels"
    puts @m.to_s_full true
    idx = (1..8)
    puts "print matrix in full mode with labels for indices #{idx.to_a.inspect}"
    puts @m.to_s_full true, idx, idx
    puts "print matrix default:"
    puts @m
  end

  it "should find the p-norms of a vector, and normalize it correctly for different ps" do
    puts "P_norms for vector \n#{@v}"
    [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000].each{ |p| puts "p_norm(#{p}) = #{@v.p_norm(p)}" }
    @v.p_norm(1).should == 13
    @v.p_norm(2).should == 7
    @v.p_norm(3).should be_close 5.896, 0.001
    @v.p_norm(1000).should == 5
    lambda{@v.p_norm(0.5)}.should raise_error
    [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000].each{ |p| puts "normalize for p = #{p}"; puts @v.p_normalize(p); puts "dot product:"; puts(@v.p_normalize(p) * @v.p_normalize(p)) }
    puts "dot product with itself:"
    puts @v*@v
    puts (@v.p_normalize(2) * @v.p_normalize(2))
    (@v*@v).should == 49
    (@v.p_normalize(2) * @v.p_normalize(2)).should == 1
  end

  it "should projection and print with a subset of keys instead of all its keys" do
    puts "vector"
    puts @v.to_s
    puts "vector 1..2"
    puts @v.to_s 1..2
    @m[7, 1]=20
    puts "matrix"
    puts @m
    puts "triplets"
    p @m.to_triplets
    puts "triplets 1..2, 1..3"
    p @m.to_triplets 1..2, 1..3
    puts "matrix projection 1..2, 1..3"
    puts @m.projection 1..2, 1..3
    puts "matrix projection nil, 1..3"
    puts @m.projection nil, 1..3
    puts "matrix projection 1..2, nil"
    puts @m.projection 1..2, nil
    puts "matrix projection nil, 1..1"
    puts @m.projection nil, 1..1
  end

  it "should do matrix * vector and matrix * matrix multiplication, and also do it with a subset of the keys" do
    (@m * @m).should be_a HashMatrix
    (@m * @v).should be_a HashMatrix.vector
    puts "matrix"
    puts @m
    puts "vector"
    puts @v
    puts "matrix * vector"
    puts @m * @v
    puts "matrix * vector 1..2"
    puts @m.*(@v, 1..2)
    puts "matrix * vector 1..1"
    puts @m.*(@v, 1..1)
    puts "matrix * matrix"
    puts @m * @m
    puts "matrix * matrix 1..2"
    puts @m.*(@m, 1..2)
    puts "matrix * matrix 1..1"
    puts @m.*(@m, 1..1)
    m=HashMatrix.from_triplets [[:a,1,1], [2,:b,2], [1,:c,3]]
    m[1,2] = -1
    puts m
    idx = [1,2,3,4,5, :a, :b, :c]
    puts m.to_s_full(true, idx, idx)
    puts m*m
    p idx
    puts (m*m).to_s_full(true, idx, idx)
    puts m*@v
    puts @v * {:a => 3, 2 => :a, 3 => 4}
  end

  it "should only store non-zero values" do
    l1 = @v.length
    @v[100] = 12
    l2= @v.length
    l2.should == (l1 + 1)
    @v[200] = 0
    l3 = @v.length
    l3.should == l2
  end
end
