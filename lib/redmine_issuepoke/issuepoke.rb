module RedmineIssuepoke
  
  class IssuePoke

    def self.each_tracker config
      if config.extrainterval.to_a.empty?
        yield Issue.open
          .on_active_project.where('issues.updated_on < ?', config.interval_time)
      else
        config.extrainterval.each do |entry|
          yield Tracker.find(entry[:tracker]).issues
            .on_active_project.where('issues.updated_on < ?', entry[:interval])
        end
      end
    end

    def self.enumerate_issues config
      each_tracker(config) do |issues|
        issues.joins(:project).where('projects.identifier not in (?)', config.excluded_projects).each do |issue|
          # TODO what to do with unassigned issues?
          next unless issue.assigned_to
          assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
          author_name = issue.author ? issue.author.name : '?'
          yield [issue, assignee_name, author_name] if block_given?
        end
      end
    end
    
    def self.preview
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue, assignee_name, author_name|
        STDERR.puts("Preview issue \##{issue.id} (#{issue.subject}), " +
          "status '#{issue.status.name}', authored by '#{author_name}', " +
          "assigned to '#{assignee_name}', " +
          "updated #{((Time.now - issue.updated_on) / (3600*24)).round(1)} days ago")
      end
    end
    
    def self.poke
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue, assignee_name, author_name|
        STDERR.puts "Poking issue \##{issue.id} (#{issue.subject})"
        note = config.poke_text.gsub('{user}', [assignee_name, author_name].join(', '))
        journal = issue.init_journal(config.poke_user, note)
        raise 'Error creating journal' unless journal
        issue.save
      end
    end
  
  end
  
end