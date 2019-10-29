module RedmineBlockUsers
  module Patches
    module UserPatch
      def self.included(base)
        base.extend ClassMethods
        base.send(:include, InstanceMethods)
        base.class_eval do
          unloadable

          class << self
            def max_failed_logins
              Setting.plugin_redmine_block_users["max_failed_logins"].to_i
            end
            # Returns the user that matches provided login and password, or nil
            def try_to_login(login, password, active_only=true)
              login = login.to_s.strip
              password = password.to_s

              # Make sure no one can sign in with an empty login or password
              return nil if login.empty? || password.empty?
              user = find_by_login(login)
              if user
                # user is already in local database
                unless user.check_password?(password)
                  if max_failed_logins > 0 && ((user.failed_logins+1) % max_failed_logins) == 0
                    length = [Setting.password_min_length.to_i + 2, 10].max
                    user.random_password(length)
                    user.save!(validate: false) if user.changed?
                    # create a new token for password recovery
                    token = Token.create!(:user => user, :action => "recovery")
                    # Don't use the param to send the email
                    recipent = user.mail
                    UserMailer.failed_logins_reset_password(token, recipent).deliver
                  end
                  user.increment_failed_logins
                  return nil 
                end
                user.reset_fail_logins
                return nil if !user.active? && active_only
              else
                # user is not yet registered, try to authenticate with available sources
                attrs = AuthSource.authenticate(login, password)
                if attrs
                  user = new(attrs)
                  user.login = login
                  user.language = Setting.default_language
                  if user.save
                    user.reload
                    logger.info("User '#{user.login}' created from external auth source: #{user.auth_source.type} - #{user.auth_source.name}") if logger && user.auth_source
                  end
                end
              end
              user.update_column(:last_login_on, Time.now) if user && !user.new_record? && user.active?
              user
            rescue => text
              raise text
            end            
          end
        end
      end
      module InstanceMethods
        def increment_failed_logins
          self.update_columns(failed_logins: self.failed_logins + 1)
        end

        def reset_fail_logins
          self.update_columns(failed_logins: 0)
        end
      end
      module ClassMethods

      end
    end
  end
end