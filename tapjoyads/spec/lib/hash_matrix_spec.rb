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
    it "should return sparse vector representation" do
      @vector.to_s.should == <<-STR.gsub(/^\s*/, '').strip
      1 -> 2
      2 -> -2
      3 -> 4
      6 -> -5
      STR
    end

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

    it "should return string representation of matrix in full mode without labels" do
      @matrix.to_s_full.should == <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
      1 0 1 0
      0 1 0 0
      -1  0 1 0
      0 0 0 1
      STR
    end

    it "should return string representation of matrix in full mode with labels" do
      @matrix.to_s_full(true).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
          [,1]  [,2]  [,3]  [,6]
      [1,]  1 0 1 0
      [2,]  0 1 0 0
      [3,]  -1  0 1 0
      [6,]  0 0 0 1
      STR
    end

    it "should return string representation of matrix in full mode with labels and with explicit indices" do
      idx = (1..8)
      @matrix.to_s_full(true, idx, idx).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
          [,1]  [,2]  [,3]  [,4]  [,5]  [,6]  [,7]  [,8]
      [1,]  1 0 1 0 0 0 0 0
      [2,]  0 1 0 0 0 0 0 0
      [3,]  -1  0 1 0 0 0 0 0
      [4,]  0 0 0 0 0 0 0 0
      [5,]  0 0 0 0 0 0 0 0
      [6,]  0 0 0 0 0 1 0 0
      [7,]  0 0 0 0 0 0 0 0
      [8,]  0 0 0 0 0 0 0 0
      STR
    end
  end

  describe "normalization and p-norms for a vector" do
    it "should find the p-norms of a vector for different ps" do
      @vector.p_norm(1).should == 13
      @vector.p_norm(1.000001).should be_close(13, 0.001)
      @vector.p_norm(2).should == 7
      @vector.p_norm(2.000001).should be_close(7, 0.001)
      @vector.p_norm(3).should be_close(5.896, 0.001)
      @vector.p_norm(1000).should == 5
      @vector.p_norm(90).should be_close(5, 0.001)
    end

    it "should return an error if trying to get pnorm with p < 1" do
      lambda{@vector.p_norm(0.5)}.should raise_error
    end

    it "should normalize vector correctly with different p-norms" do
      pnorms_and_dots = [
        [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000], #values for p-norm
        [0.2899, 0.2899, 1.0, 1.0, 1.41, 1.92, 1.96, 1.96, 1.96] #dot products for different p-norms
      ]
      pnorms_and_dots.transpose.each do |p, dot|
        (@vector.p_normalize(p) * @vector.p_normalize(p)).should be_close(dot, 0.001)
      end
      (@vector * @vector).should == 49
      (@vector.p_normalize(2) * @vector.p_normalize(2)).should == 1
    end
  end

  describe "projections to a subspace given by a subset of keys and matrix multiplications" do
    it "should return string representation of a projection to a subset of keys" do
      @vector.to_s(1..2).should == <<-STR.gsub(/^\s*/, '').strip
      1 -> 2
      2 -> -2
      STR
      @matrix[7, 1]=20
      @matrix.to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, 1], [6, 6, 1], [7, 1, 20]]
      @matrix.to_triplets(1..2, 1..3).should == [[1, 1, 1], [1, 3, 1], [2, 2, 1]]
      @matrix.projection(nil, 1..3).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, 1], [7, 1, 20]]
      @matrix.projection(1..2, nil).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1]]
      @matrix.projection(nil, 1..1).to_triplets.should == [[1, 1, 1], [3, 1, -1], [7, 1, 20]]
    end

    it "should do matrix and vector operations, and also do it with a subset of the keys" do
      (@matrix * @matrix).should be_a HashMatrix
      (@matrix * @vector).should be_a HashMatrix.vector
      (@matrix * @vector).to_pairs.should == [[1, 6], [2, -2], [3, 2], [6, -5]]
      (@matrix.*(@vector, 1..2)).to_pairs.should == [[1, 2], [2, -2], [3, -2]]
      (@matrix.*(@vector, 1..1)).to_pairs.should == [[1, 2], [3, -2]]
      (@matrix * @matrix).to_triplets.should == [[1, 3, 2], [2, 2, 1], [3, 1, -2], [6, 6, 1]]
      (@matrix.*(@matrix, 1..2)).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, -1]]
      (@matrix.*(@matrix, 1..1)).to_triplets.should == [[1, 1, 1], [1, 3, 1], [3, 1, -1], [3, 3, -1]]
      m=HashMatrix.from_triplets [[:a,1,1], [2,:b,2], [1,:c,3]]
      m[1,2] = -1
      idx = [1,2,3,4,5, :a, :b, :c]
      m.to_s_full(true, idx, idx).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
          [,1]  [,2]  [,3]  [,4]  [,5]  [,a]  [,b]  [,c]
      [1,]  0 -1  0 0 0 0 0 3
      [2,]  0 0 0 0 0 0 2 0
      [3,]  0 0 0 0 0 0 0 0
      [4,]  0 0 0 0 0 0 0 0
      [5,]  0 0 0 0 0 0 0 0
      [a,]  1 0 0 0 0 0 0 0
      [b,]  0 0 0 0 0 0 0 0
      [c,]  0 0 0 0 0 0 0 0
      STR
      (m*m).to_s_sparse.should == <<-STR.gsub(/^\s*/, '').strip
      (1, b) -> -2
      (a, 2) -> -1
      (a, c) -> 3
      STR
      (m*m).to_s_full(true, idx, idx).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
          [,1]  [,2]  [,3]  [,4]  [,5]  [,a]  [,b]  [,c]
      [1,]  0 0 0 0 0 0 -2  0
      [2,]  0 0 0 0 0 0 0 0
      [3,]  0 0 0 0 0 0 0 0
      [4,]  0 0 0 0 0 0 0 0
      [5,]  0 0 0 0 0 0 0 0
      [a,]  0 -1  0 0 0 0 0 3
      [b,]  0 0 0 0 0 0 0 0
      [c,]  0 0 0 0 0 0 0 0
      STR
      (m*@vector).to_pairs.should == [[1, 2], [:a, 2]]
      (@vector * {:a => 3, 2 => :a, 3 => 4}).should == 16
      p (@vector + @vector).to_pairs.should == [[1, 4], [2, -4], [3, 8], [6, -10]]
      p (@vector + 3).to_pairs.should == [[1, 5], [2, 1], [3, 7], [6, -2]]
    end
  end

  describe "sparse representation" do
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
end
