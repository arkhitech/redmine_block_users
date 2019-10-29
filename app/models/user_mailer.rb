class UserMailer < ActionMailer::Base
  layout 'mailer'
  helper :application
  helper :issues
  helper :custom_fields

  include Redmine::I18n
  include Roadie::Rails::Automatic

  def self.default_url_options
    Mailer.default_url_options
  end  
  
  def failed_logins_reset_password(token, recipent)
    set_language_if_valid(token.user.language)
    recipient ||= token.user.mail
    @token = token
    @url = url_for(:controller => 'account', :action => 'lost_password', :token => token.value)
    mail :to => recipient,
      :subject => l(:mail_subject_failed_logins_reset_password, Setting.app_title)
  end
    
end