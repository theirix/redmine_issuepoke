module RedmineIssuepoke
  
  class IssuePoke

    def self.enumerate_issues config
      Issue.open.on_active_project
          .where('issues.updated_on < ?', config.interval_time)
          .joins(:project).where('projects.name not in (?)', config.excluded_projects).each do |issue|
        yield issue if block_given?
      end
    end
    
    def self.preview
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue|
        assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
        STDERR.puts "Would like to poke issue \##{issue.id} (#{issue.subject}) for user '#{assignee_name}'"
      end
    end
    
    def self.poke
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue|
        STDERR.puts "Poking issue \##{issue.id} (#{issue.subject})"
        assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
        note = config.poke_text.gsub('{user}', assignee_name)
        journal = issue.init_journal(config.poke_user, note)
        raise 'Error creating journal' unless journal
        issue.save
      end
    end
  
  end
  
end