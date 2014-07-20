module RedmineIssuepoke
  
  class Config
    DEFAULT_INTERVAL = 1
  
    def logger
       Rails.logger if Rails.logger.info?
    end

    def poke_user
      unless @poke_user
        poke_user_email = Setting.plugin_redmine_issuepoke['issuepoke_pokeuser']
        if poke_user_email.blank? 
          @poke_user = User.where(:admin => true).first
        else
          @poke_user = User.where(:mail => poke_user_email).first
          raise 'Cannot find poke user ' + poke_user_email unless @poke_user
        end
        logger.info("redmine_pokeuser: using poke user #{@poke_user.mail}") if logger
      end
      @poke_user
    end

    def interval_time
      unless @interval_time    
        @interval_time = (Setting.plugin_redmine_issuepoke['issuepoke_interval'] or DEFAULT_INTERVAL).to_i.days.ago
        logger.info("redmine_pokeuser: using interval #{@interval_time}") if logger
      end
      @interval_time
    end
    
    def poke_text
      unless @poke_text
        @poke_text = Setting.plugin_redmine_issuepoke['issuepoke_poketext']
        logger.info("redmine_pokeuser: using poke text #{@poke_text}") if logger
      end
      @poke_text
    end
    
    def excluded_projects
      unless @excluded_projects
        @excluded_projects = (Setting.plugin_redmine_issuepoke['issuepoke_excludedprojects'] or '')
          .split(',').map(&:strip) - ['']
        logger.info("redmine_pokeuser: exclude projects #{@excluded_projects.join(',')}") if logger
      end
      @excluded_projects
    end

    def extrainterval
      unless @extra_interval
        @extra_interval = []
        Setting.plugin_redmine_issuepoke.each do |key, value|
          if key =~ /^issuepoke_interval_(\d+)$/
            tracker_id = $1.to_i
            interval = (value or '') == '' ? self.interval_time : value.to_i.days.ago
            @extra_interval << {tracker: tracker_id, interval: interval }
          end
        end
        logger.info("redmine_pokeuser: using intervals #{@extra_interval}") if logger
      end
      @extra_interval
    end

  end

end