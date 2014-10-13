# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
# for development purposes:
# set :environment, "development" 
# set :output, {:error => "log/cron_error_log.log", :standard => "log/cron_log.log"}

every 30.minutes do
  rake "assignment:send_emails_to_volunteers"
end

every :day do
	rake "assignment:send_emails_to_superstar_reviewers"
end

every :day do
	rake "assignment:send_emails_to_started_answers"
end

every :day do
	rake "assignment:send_emails_to_unrevised_answers"
end

#begin vineet
# every :hour do
#   rake "assignment:send_emails_batched"
# end 
#end vineet