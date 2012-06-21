class OneOffs
  def self.backfill_partner_live_date

    File.open('lib/one_offs/20120606_backfill_livedate.txt') do |f|
      while line = f.gets
        id, stamp = line.chomp.split('|')
        helper_backfill_partner_live_date(id, stamp)
      end
    end
    puts "Applied live date to partners from archived conversion data"
  end

  def self.helper_backfill_partner_live_date(id, stamp)
    begin
      p = Partner.find(id)
      p.live_date = Time.zone.parse(stamp)
      p.save!
    rescue => e
      puts "Failed to update Partner #{id}: #{e.class} #{e.message}"
    end
  end
end
