require 'spec_helper'

describe HashMatrix::HashVector do
  before do
    @vector = HashMatrix.vector.from_pairs([[1,2], [2,-2], [3,4], [6,-5]])
  end

  describe ".from_pairs" do
    it "creates a vector from an array of pairs" do
      HashMatrix.vector.from_pairs([[1,1], [2,2]]).should be_a HashMatrix.vector
    end
  end

  describe "#to_s" do
    context "given no parameters" do
      it "returns a sparse vector representation" do
        @vector.to_s.should == <<-STR.gsub(/^\s*/, '').strip
        1 -> 2
        2 -> -2
        3 -> 4
        6 -> -5
        STR
      end
    end

    context "given some indices as parameters" do
      it "returns a projection of the vector into the indices space" do
        @vector.to_s(1..4).should == <<-STR.gsub(/^\s*/, '').strip
        1 -> 2
        2 -> -2
        3 -> 4
        STR
      end
    end
  end

  describe "#p_norm" do
    context "given a number in valid range >= 1" do
      it "returns the correct value for the p_norm" do
        @vector.p_norm(1).should == 13
        @vector.p_norm(1.000001).should be_close(13, 0.001)
        @vector.p_norm(2).should == 7
        @vector.p_norm(2.000001).should be_close(7, 0.001)
        @vector.p_norm(3).should be_close(5.896, 0.001)
        @vector.p_norm(1000).should == 5
        @vector.p_norm(90).should be_close(5, 0.001)
      end
    end

    context "given no input" do
      it "defaults to euclidean p_norm (p = 2)" do
        @vector.p_norm.should == @vector.p_norm(2)
      end
    end

    context "given a number less than 1" do
      it "raises an error" do
        expect{ @vector.p_norm(0.5) }.to raise_error
      end
    end
  end

  describe "#*" do
    context "given another vector" do
      it "is a number" do
        (@vector * @vector).should be_a Numeric
      end

      it "returns the scalar (dot) product of the two vectors" do
        (@vector * @vector).should == 49
      end
    end

    context "given a scalar" do
      it "is a vector" do
        (@vector * 2).should be_a HashMatrix.vector
      end

      it "returns a vector scaled by the scalar's value" do
        (@vector * 2).to_s.should == <<-STR.gsub(/^\s*/, '').strip
        1 -> 4
        2 -> -4
        3 -> 8
        6 -> -10
        STR
      end
    end

    context "given a hash" do
      it "treats it as a vector and multiplies it" do
        (@vector * {:a => 3, 2 => :a, 3 => 4}).should == 16
      end
    end
  end

  describe "#+" do
    context "given another vector" do
      it "adds the two vectors" do
      (@vector + @vector).to_pairs.should == [[1, 4], [2, -4], [3, 8], [6, -10]]
      end
    end

    context "given a scalar" do
      it "adds the scalar to all the non-zero elements of the vector" do
        (@vector + 3).to_pairs.should == [[1, 5], [2, 1], [3, 7], [6, -2]]
      end
    end
  end

  describe "#normalize" do
    context "given no value for p_norm" do
      it "normalizes vector correctly in an euclidean way, so that its scalar product is 1" do
        (@vector.p_normalize * @vector.p_normalize).should == 1
      end
    end

    context "given different valid p_norms" do
      it "normalizes vector correctly as measured by its scalar product" do
        pnorms_and_dots = [
          [1, 1.0000001, 2, 2.0000001, 3, 10, 90, 99, 10000], #values for p-norm
          [0.2899, 0.2899, 1.0, 1.0, 1.41, 1.92, 1.96, 1.96, 1.96] #scalar products for different p-norms
        ]
        pnorms_and_dots.transpose.each do |p, dot|
          (@vector.p_normalize(p) * @vector.p_normalize(p)).should be_close(dot, 0.001)
        end
      end
    end
  end

  describe "#length" do
    context "given that we added a non-zero element to the vector" do
      it "increases in length by one" do
        l1 = @vector.length
        @vector[100] = 12
        @vector.length.should == l1 + 1
      end
    end

    context "given that we added a zero element to the vector" do
      it "does not increase in length, it does not store zeros" do
        l1 = @vector.length
        @vector[100] = 0
        @vector.length.should == l1
      end
    end
  end
end


describe HashMatrix do
  before do
    @matrix = HashMatrix.eye(3)
    @matrix[1, 3] = 1
    @matrix[3, 1] = -1
    @matrix[6, 6] = 1
    @vector = HashMatrix.vector.from_pairs([[1,2], [2,-2], [3,4], [6,-5]])
  end

  describe ".vector" do
    it "returns a HashVector" do
      HashMatrix.vector.should == HashMatrix::HashVector
    end
  end

  describe ".from_triplets" do
    it "creates a matrix from an array of triplets of the form row, col, value" do
      HashMatrix.from_triplets([1,1,3]).should be_a HashMatrix
    end
  end

  describe "#to_s_sparse" do
    it "returns a sparse matrix representation" do
      @matrix.to_s_sparse.should == <<-STR.gsub(/^\s*/, '').strip
      (1, 1) -> 1
      (1, 3) -> 1
      (2, 2) -> 1
      (3, 1) -> -1
      (3, 3) -> 1
      (6, 6) -> 1
      STR
    end
  end

  describe "#to_s_full" do
    context "given no labels parameters" do
      it "returns full mode representation without labels" do
        @matrix.to_s_full.should == <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
        1 0 1 0
        0 1 0 0
        -1  0 1 0
        0 0 0 1
        STR
      end
    end

    context "given labels = true" do
      it "returns full mode representation with labels" do
        @matrix.to_s_full(true).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
        [,1]  [,2]  [,3]  [,6]
        [1,]  1 0 1 0
        [2,]  0 1 0 0
        [3,]  -1  0 1 0
        [6,]  0 0 0 1
        STR
      end
    end

    context "given labels = true and indices" do
      it "returns full mode representation with labels for the indices given" do
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

    context "with non-numeric indices" do
      before do
        @matrix=HashMatrix.from_triplets [[:a,1,1], [2,:b,2], [1,:c,3]]
        @matrix[1,2] = -1
        @indices = [1,2,3,4,5, :a, :b, :c]
      end

      it "still returns a full mode representation with labels for the indices given" do
        @matrix.to_s_full(true, @indices, @indices).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
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
      end
    end
  end

  describe "#*" do
    context "given another matrix" do
      it "returns a matrix" do
        (@matrix * @matrix).should be_a HashMatrix
      end

      it "returns a matrix with the correct values for multiplication" do
        (@matrix * @matrix).to_triplets.should == [[1, 3, 2], [2, 2, 1], [3, 1, -2], [6, 6, 1]]
      end
    end

    context "given a matrix and a set of indices" do
      it "returns a matrix with the correct values for multiplication in the span defined by the given indices" do
        (@matrix.*(@matrix, 1..2)).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, -1]]
      end
    end

    context "given a vector" do
      it "returns a vector" do
        (@matrix * @vector).should be_a HashMatrix.vector
      end

      it "returns a vector with the correct values for multiplication" do
        (@matrix * @vector).to_pairs.should == [[1, 6], [2, -2], [3, 2], [6, -5]]
      end
    end

    context "given a vector and some indices" do
      it "returns a vector with the correct values for multiplication in that subspace" do
        (@matrix.*(@vector, 1..2)).to_pairs.should == [[1, 2], [2, -2], [3, -2]]
      end
    end

    context "with non-numeric indices" do
      before do
        @matrix=HashMatrix.from_triplets [[:a,1,1], [2,:b,2], [1,:c,3]]
        @matrix[1,2] = -1
        @indices = [1,2,3,4,5, :a, :b, :c]
      end

      it "still multiplies correctly" do
        (@matrix * @matrix).to_s_sparse.should == <<-STR.gsub(/^\s*/, '').strip
        (1, b) -> -2
        (a, 2) -> -1
        (a, c) -> 3
        STR
      end

      it "displays full representation correctly, without trouble on the sort of indices" do
        (@matrix * @matrix).to_s_full(true, @indices, @indices).should == "   \t" + <<-STR.gsub(/^\s*/, '').strip.gsub(/ +/, "\t")
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
      end
    end
  end

  describe "#to_triplets" do
    context "standard without parameters" do
      it "turns a matrix into an array of triplets of the form [row, col, value]" do
        @matrix.to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, 1], [6, 6, 1]]
      end
    end

    context "with indices for rows and columns given" do
      it "returns an array of triplets for the projection of the matrix into the subspace spanned by the row and column indices" do
        @matrix.to_triplets(1..2, 1..3).should == [[1, 1, 1], [1, 3, 1], [2, 2, 1]]
      end
    end
  end

  describe "#projection" do
    before do
      @matrix[7, 1]=20
    end
    context "when indices for rows and or columns are given" do
      it "returns the submatrix for the projection of the current matrix into the subspace spanned by the row and column indices" do
        @matrix.projection(nil, 1..3).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1], [3, 1, -1], [3, 3, 1], [7, 1, 20]]
        @matrix.projection(1..2, nil).to_triplets.should == [[1, 1, 1], [1, 3, 1], [2, 2, 1]]
        @matrix.projection(nil, 1..1).to_triplets.should == [[1, 1, 1], [3, 1, -1], [7, 1, 20]]
      end
    end

    context "when indices given are nil" do
      it "returns a projection onto the full space of itself, i.e. a copy of itself" do
        @matrix.projection(nil, nil).to_triplets.should == @matrix.to_triplets
      end
    end
  end
end
