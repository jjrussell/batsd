class Friendship < SimpledbResource
  self.key_format  = 'gamer_id.following_id'
  self.domain_name = 'friendships'

  self.sdb_attr :following_id
  self.sdb_attr :gamer_id

  def self.establish_friendship(gamer_id, following_id)
    friendship = Friendship.new(:key => "#{gamer_id}.#{following_id}", :consistent => true)
    if friendship.new_record?
      friendship.gamer_id = gamer_id
      friendship.following_id = following_id
      friendship.serial_save
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
end
