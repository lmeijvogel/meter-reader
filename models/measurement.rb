class Measurement
  attr_accessor :time_stamp, :stroom_dal, :stroom_piek, :stroom_current, :gas

  def to_s
    date = self.time_stamp.strftime("%d-%m-%y %H:%M:%S")

    "#{date}: #{stroom_dal} - #{stroom_piek} - #{stroom_current} - #{gas}"
  end
end
