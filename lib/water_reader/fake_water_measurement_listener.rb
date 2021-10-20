module WaterReader
  class FakeWaterMeasurementListener
    def initialize(odds_of_tick)
      @odds_of_tick = odds_of_tick
    end

    def read
      sleep 1

      random_event
    end

    def ready?
      true
    end

    def random_event

      if rand < @odds_of_tick
        "USAGE"
      else
        "TICK"
      end
    end
  end
end
