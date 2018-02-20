Redmine::Plugin.register :redmine_issuepoke do
  name 'Redmine IssuePoke plugin'
  author 'Eugene Seliverstov'
  author_url 'http://omniverse.ru'
  description 'IssuePoke plugin'
  version '0.0.5'
  url 'http://github.com/theirix/redmine_issuepoke'

  require 'redmine_issuepoke'

  settings :default => {
    'issuepoke_pokeuser' => '', 
    'issuepoke_excludedprojects' => '',
    'issuepoke_interval' => RedmineIssuepoke::Config::DEFAULT_INTERVAL,
    'issuepoke_poketext' => "Dear {user}!\nPlease fix this issue!\n",
    'issuepoke_feedback_poketext' => "",
  },
  :partial => 'settings/issuepoke_settings'  
end
