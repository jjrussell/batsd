class Friendship < SimpledbResource
  self.key_format  = 'gamer_id.following_id'
  self.domain_name = 'friendships'

  self.sdb_attr :following_id
  self.sdb_attr :gamer_id

  def self.establish_friendship(gamer_id, following_id)
    friendship = Friendship.new(:key => "#{gamer_id}.#{following_id}")
    if friendship.new_record?
      friendship.gamer_id = gamer_id
      friendship.following_id = following_id
      friendship.save
    end
  end
end
