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
        next unless issue.assigned_to

        assignee_name = issue.assigned_to ? issue.assigned_to.name : 'all'
        author_name = issue.author ? issue.author.name : '?'

        journals = issue.journals.order(created_on: :desc)
        # ensure that last meaningful comment was more than 6 days ago
        possible_user_seq = [[assignee_name], [author_name],
                             [assignee_name, author_name],
                             [author_name, assignee_name]]
        possible_notes = possible_user_seq.map { |seq| poke_text.gsub('{user}', seq.uniq.join(', ')) }

        last_good_journal = journals.find{ |j| !possible_notes.include?(j.notes) }

        if last_good_journal
          #STDERR.puts("last good comment was at #{last_good_journal.created_on}: " +
          #            (last_good_journal.notes ? last_good_journal.notes[0...50].gsub("\n", '  |') : ''))
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

      issue_ids = []
      self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
        STDERR.puts("Preview feedback issue \##{issue.id} (#{issue.subject}) at #{issue.project.identifier}, " +
          "status '#{issue.status.name}', authored by '#{author_name}', " +
          "assigned to '#{assignee_name}', " +
          "with text '#{poke_text.split('\n').first}...', ")
        issue_ids.append(issue.id)
      end

      issues = Issue.find(issue_ids)
      STDERR.puts("Updated #{issues.size} issues")

      # debug mails
      #self.send_report(User.where(admin: true, Issue.first(3))
    end

    def self.poke
      config = RedmineIssuepoke::Config.new

      issue_ids = []
      self.enumerate_issues(config) do |issue, assignee_name, author_name, poke_text|
        STDERR.puts "Poking feedback issue \##{issue.id} (#{issue.subject}) at #{issue.project.identifier}"
        note = poke_text.gsub('{user}', [assignee_name].uniq.join(', '))
        journal = issue.init_journal(config.poke_user, note)
        raise 'Error creating journal' unless journal
        issue_ids.append(issue.id)
        issue.save
      end

      issues = Issue.find(issue_ids)
      STDERR.puts("Updated #{issues.size} issues")

      if !config.feedback_report_emails.inspect.empty? && !issues.empty?
        to = config.feedback_report_emails.compact
        self.send_report(to, issues)
      end
    end

    def self.send_report(to, issues)
      STDERR.puts("Send report to users: #{to.join(',')}")

      raise_delivery_errors = ActionMailer::Base.raise_delivery_errors
      ActionMailer::Base.raise_delivery_errors = true
      begin
        mail = ReportMailer.report(to, issues)
        mail.deliver_now()
        # need to work with async tasks
        sleep(10)
      ensure
        ActionMailer::Base.raise_delivery_errors = raise_delivery_errors
      end
    end


  end

end
