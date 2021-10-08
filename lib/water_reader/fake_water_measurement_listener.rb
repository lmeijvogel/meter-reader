module WaterReader
  class FakeWaterMeasurementListener
    def read
      sleep 1

      random_event
    end

    def ready?
      true
    end

    def random_event
      if rand(10) < 2
        "USAGE"
      else
        "TICK"
      end
    end
  end
end
