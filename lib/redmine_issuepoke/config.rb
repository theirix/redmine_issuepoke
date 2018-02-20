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
          @poke_user = User.find_by_mail(poke_user_email)
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

    def feedback_poke_text
      unless @feedback_poke_text
        @feedback_poke_text = Setting.plugin_redmine_issuepoke['issuepoke_feedbackpoketext']
        logger.info("redmine_pokeuser: using feedback poke text #{@feedback_poke_text}") if logger
      end
      @feedback_poke_text
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
        logger.info("redmine_pokeuser: using extra intervals #{@extra_interval}") if logger
      end
      @extra_interval
    end

    def extrapoketext
      unless @extra_poketext
        @extra_poketext = []
        Setting.plugin_redmine_issuepoke.each do |key, value|
          if key =~ /^issuepoke_poketext_(\d+)$/
            tracker_id = $1.to_i
            poke_text = (value or '') == '' ? self.poke_text : value
            @extra_poketext << {tracker: tracker_id, poke_text: poke_text }
          end
        end
        logger.info("redmine_pokeuser: using extra poke text #{@extra_poketext}") if logger
      end
      @extra_poketext
    end

  end

end