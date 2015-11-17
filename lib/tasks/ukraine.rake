namespace :application do
  namespace :load do
    namespace :ukraine do
      desc "Load latest Ukrainian People data from EveryPolitician"
      task people: [:environment, :set_logger_to_stdout] do
        DataLoader::Ukraine::People.load!
      end

      desc "Load Ukrainian vote_events for a date or range of dates"
      task :vote_events, [:from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
        from_date = Date.parse(args[:from_date])
        to_date = if args[:to_date] && args[:to_date] == "today"
                    Date.today
                  elsif args[:to_date]
                    Date.parse(args[:to_date])
                  else
                    from_date
                  end

        (from_date..to_date).each do |date|
          DataLoader::Ukraine::VoteEvents.load!(date)
        end
      end
    end
  end
end
