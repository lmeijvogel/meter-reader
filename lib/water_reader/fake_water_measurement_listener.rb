module WaterReader
  class FakeWaterMeasurementListener
    def read
      sleep 3

      random_event
    end

    def random_event
      if rand(10) < 4
        "USAGE"
      else
        "TICK"
      end
    end
  end
end
