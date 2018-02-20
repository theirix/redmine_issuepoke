module RedmineIssuepoke

  class IssueFeedbackPoke

    def self.enumerate_issues config
      poke_text = config.feedback_poke_text
      return if poke_text.nil? || poke_text.empty?

      # if the status=Feedback AND due_date is missing or expired AND last updated 6 days ago
      excluded_project_identifiers = config.excluded_projects.empty? ? [''] : config.excluded_projects

      issues = Issue.open.joins(:project).
        where("#{Project.table_name}.identifier not in (?)", excluded_project_identifiers).
        joins(:status).
        where("#{IssueStatus.table_name}.name = 'Feedback'").
        where("due_date is NULL or due_date < ?", Date.today)
      issues.each do |issue|
        # TODO what to do with unassigned issues?
        next unless issue.assigned_to

        assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
        author_name = issue.author ? issue.author.name : '?'

        journals = issue.journals.order(created_on: :desc)
        # ensure that last meaningful comment was more than 6 days ago
        possible_notes = [
          poke_text.gsub('{user}', [assignee_name, author_name].uniq.join(', ')),
          poke_text.gsub('{user}', [author_name, assignee_name].uniq.join(', '))]

        last_good_journal = journals.find{ |j| !possible_notes.include?(j.notes) }

        if last_good_journal
          STDERR.puts("last good comment was at #{last_good_journal.created_on}: " +
                      (last_good_journal.notes ? last_good_journal.notes[0...20] : ''))
          updated_long_time_ago = last_good_journal.created_on < 6.days.ago
          next unless updated_long_time_ago
        end

        # do not notify on weekend
        weekends = Date.today.sunday? || Date.today.saturday?
        next if weekends

        yield [issue, assignee_name, author_name, poke_text] if block_given?
      end
    end

    def self.preview
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
        STDERR.puts("Preview feedback issue \##{issue.id} (#{issue.subject}), " +
          "status '#{issue.status.name}', authored by '#{author_name}', " +
          "assigned to '#{assignee_name}', " +
          "with text '#{poke_text.split('\n').first}...', ")
      end
    end

    def self.poke
      config = RedmineIssuepoke::Config.new
      self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
        STDERR.puts "Poking feedback issue \##{issue.id} (#{issue.subject})"
        note = poke_text.gsub('{user}', [assignee_name, author_name].uniq.join(', '))
        # XXX disable now
        next
        journal = issue.init_journal(config.poke_user, note)
        raise 'Error creating journal' unless journal
        issue.save
      end
    end

  end

end
