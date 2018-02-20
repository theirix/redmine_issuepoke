namespace :issuepoke do

  desc <<-END_DESC
  Find stalled issues and poke participants about resolving these issues
  END_DESC
  task :poke => :environment do
    RedmineIssuepoke::IssuePoke.poke()
    RedmineIssuepoke::IssueFeedbackPoke.poke()
  end

  desc <<-END_DESC
  Preview stalled issues
  END_DESC
  task :preview => :environment do
    RedmineIssuepoke::IssuePoke.preview()
    RedmineIssuepoke::IssueFeedbackPoke.preview()
  end
end
