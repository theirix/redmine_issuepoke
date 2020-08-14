module RedmineIssuepoke
  
  class IssuePoke

    def self.each_tracker config
      Tracker.all.each do |tracker|
        extrainterval_entry = config.extrainterval.find { |x| x[:tracker] == tracker.id }
        interval = extrainterval_entry ? extrainterval_entry[:interval] : config.interval_time
        extrapoketext_entry = config.extrapoketext.find { |x| x[:tracker] == tracker.id }        
        poke_text = extrapoketext_entry ? extrapoketext_entry[:poke_text] : config.poke_text
        STDERR.puts "Tracker #{tracker.name} uses interval #{interval} and text #{poke_text.split('\n').first}..."
        yield [tracker.issues.open.on_active_project.where('issues.updated_on < ?', interval),
          poke_text
        ]
      end
    end

    def self.enumerate_issues config
      # avoid rails 3 bug with empty array interpreted as NULL
      excluded_project_identifiers = config.excluded_projects.empty? ? [''] : config.excluded_projects
      each_tracker(config) do |issues, poke_text|
        issues.joins(:project).where('projects.identifier not in (?)', excluded_project_identifiers).each do |issue|
          # TODO what to do with unassigned issues?
          next unless issue.assigned_to
          assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
          author_name = issue.author ? issue.author.name : '?'
          yield [issue, assignee_name, author_name, poke_text] if block_given?
        end
      end
    end
    
    def self.preview
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
        STDERR.puts("Preview issue \##{issue.id} (#{issue.subject}), " +
          "status '#{issue.status.name}', authored by '#{author_name}', " +
          "assigned to '#{assignee_name}', " +
          "with text '#{poke_text.split('\n').first}...', " +
          "updated #{((Time.now - issue.updated_on) / (3600*24)).round(1)} days ago")
      end
    end
    
    def self.poke
      config = RedmineIssuepoke::Config.new
      Mailer.with_synched_deliveries do
        self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
          STDERR.puts "Poking issue \##{issue.id} (#{issue.subject})"
          note = poke_text.gsub('{user}', [assignee_name, author_name].uniq.join(', '))
          journal = issue.init_journal(config.poke_user, note)
          raise 'Error creating journal' unless journal
          issue.save(validate: false)
        end
      end
    end
  
  end
  
end
