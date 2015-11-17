module DataLoader
  module Ukraine
    class People
      URL = ENV["DEBUG_URL"] || "https://raw.githubusercontent.com/everypolitician/everypolitician-data/master/data/Ukraine/Verkhovna_Rada/ep-popolo-v1.0.json"

      def self.load!
        DataLoader::Ukraine::Popolo.load!(URL)
      end
    end
  end
end
