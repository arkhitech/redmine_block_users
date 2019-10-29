Redmine::Plugin.register :redmine_block_users do
  Rails.configuration.to_prepare do
    require_dependency 'user'
    User.send(:include, RedmineBlockUsers::Patches::UserPatch)
    
  end  
  name 'Redmine Block Users plugin'
  author 'Hisham Malik/Arkhitech'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://www.arkhitech.com'
  author_url 'http://www.arkhitech.com'

  settings default: {
    'max_failed_logins' => 7
  }, partial: 'block_user_settings'
end
