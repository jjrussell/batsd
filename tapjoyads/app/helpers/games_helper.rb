module GamesHelper
  def change_link(exists)
    exists ? "(#{t('text.games.change')})" : "(#{t('text.games.add')})"
  end
end
