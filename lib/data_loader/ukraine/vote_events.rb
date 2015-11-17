module DataLoader
  module Ukraine
    class VoteEvents
      URL = ENV["DEBUG_URL"] || "https://arcane-mountain-8284.herokuapp.com/vote_events/"

      def self.load!(date)
        DataLoader::Ukraine::Popolo.load!(URL + date.to_s)
      end
    end
  end
end
