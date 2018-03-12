require 'mailer'

class ReportMailer < Mailer
  def report(to_users, issues)
    @issues = issues
    mail :to => to_users, :subject => "Feedback report"
  end
end
