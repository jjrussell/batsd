module GamesHelper
  def change_or_add (action)
    exists = @current_gamer.send("#{action}?")

    exists ? "(#{t('text.games.change')})" : "(#{t('text.games.add')})"
  end
end
