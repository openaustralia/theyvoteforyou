namespace :application do
  namespace :load do
    namespace :ukraine do
      desc "Load latest Ukrainian People data from EveryPolitician"
      task people: [:environment, :set_logger_to_stdout] do
        DataLoader::Ukraine::People.new.load!
      end

      desc "Load Ukrainian vote_events for a date or range of dates. Omit dates to load all new ones"
      task :vote_events, [:from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
        from_date = args[:from_date] ? Date.parse(args[:from_date]) : Division.order(:date).pluck(:date).last + 1
        to_date = if args[:to_date]
                    Date.parse(args[:to_date])
                  elsif !args[:from_date]
                    Date.today
                  else
                    from_date
                  end

        (from_date..to_date).each do |date|
          DataLoader::Ukraine::VoteEvents.new(date).load!
        end
      end
    end
  end
end
