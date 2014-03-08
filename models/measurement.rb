class Measurement
  attr_accessor :time_stamp, :time_stamp_utc, :stroom_dal, :stroom_piek, :stroom_current, :gas
  attr_accessor :diff_stroom_dal, :diff_stroom_piek, :diff_gas

  def to_s
    date = self.time_stamp.strftime("%d-%m-%y %H:%M:%S")

    "#{date}: #{stroom_dal} - #{stroom_piek} - #{stroom_current} - #{gas}"
  end
end
