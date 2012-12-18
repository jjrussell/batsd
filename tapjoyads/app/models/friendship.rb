class Friendship < SimpledbResource
  include RiakMirror
  mirror_configuration :riak_bucket_name => "friendships", :read_from_riak => true

  self.key_format  = 'gamer_id.following_id'
  self.domain_name = 'friendships'

  self.sdb_attr :following_id
  self.sdb_attr :gamer_id

  def self.establish_friendship(gamer_id, following_id)
    friendship = Friendship.new(:key => "#{gamer_id}.#{following_id}", :consistent => true)
    if friendship.new_record?
      friendship.gamer_id = gamer_id
      friendship.following_id = following_id
      friendship.save
    end
  end

  def self.following_ids(id)
    Friendship.select(:where => "gamer_id = '#{id}'", :consistent => true)[:items].map do |f|
      f.following_id
    end
  end

  def self.follower_ids(id)
    Friendship.select(:where => "following_id = '#{id}'", :consistent => true)[:items].map do |f|
      f.gamer_id
    end
  end

  def self.connected?(left, right)
    self.new(:key => "#{left.id}.#{right.id}").present? ||
    self.new(:key => "#{right.id}.#{left.id}").present?
  end
end
