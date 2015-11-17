namespace :application do
  namespace :load do
    namespace :ukraine do
      desc "Load Popolo data from a URL"
      task :popolo, [:url] => [:environment, :set_logger_to_stdout] do |t, args|
        DataLoader::Ukraine::Popolo.load!(args[:url])
      end

      desc "Load Popolo for a date range, appending the date to a base url"
      task :popolo_date_range, [:base_url, :from_date, :to_date] => [:environment, :set_logger_to_stdout] do |t, args|
        from_date = Date.parse(args[:from_date])
        to_date = args[:to_date] ? Date.parse(args[:to_date]) : Date.today

        (from_date..to_date).each do |date|
          DataLoader::Ukraine::Popolo.load!(args[:base_url] + date.to_s)
        end
      end
    end
  end
end
