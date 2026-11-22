# frozen_string_literal: true

module ApiLog
  # Keeps a long-running task from taking more than about half of a service it shares with the site. After each
  # call, the next one waits until at least as long as that call took (plus a fixed gap) has passed, so a busy
  # service, whose calls take longer, gets longer breaks. Time spent on other work counts towards the wait.
  #
  # Written for ApiLog::Upload reading api_statistics from maindb, whose gp2 storage on a db.t3.small runs out of
  # burst credit under a full-speed copy (#1916).
  class Pacer
    attr_reader :waited

    def initialize(gap:)
      @gap = gap
      @ready_at = 0.0
      @waited = 0.0
    end

    def call
      wait = @ready_at - now
      if wait.positive?
        self.class.pause(wait)
        @waited += wait
      end
      started = now
      result = yield
      finished = now
      @ready_at = finished + (finished - started) + @gap
      result
    end

    # Separate so specs can skip the waiting
    def self.pause(seconds)
      sleep(seconds)
    end

    private

    def now
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
  end
end
