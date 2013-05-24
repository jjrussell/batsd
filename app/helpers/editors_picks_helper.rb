module EditorsPicksHelper
  def time_ago_or_from_now(time)
    word = (time < Time.zone.now) ? 'ago' : 'from now'
    "#{time_ago_in_words(time)} #{word}"
  end
end
