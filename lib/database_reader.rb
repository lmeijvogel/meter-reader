require 'ostruct'
require_relative '../models/usage.rb'

class DatabaseReader
  def initialize(client)
    @client = client
  end

  def read
    query = "SELECT
      MIN(#{adjusted_time_stamp}) as ts,
      TRUNCATE(MIN(stroom_piek+stroom_dal),3) as d_totaal,
      TRUNCATE(MIN(gas),3) as d_gas
    FROM measurements
    #{where}
    GROUP BY #{granularity}"

    @client.query(query).map do |row|
      usage = Usage.new
      usage.stroom_totaal = row["d_totaal"]
      usage.gas = row["d_gas"]
      usage.time_stamp = row["ts"].to_datetime

      usage
    end
  end

  def day=(date)
    start_date = sql_date(date)
    next_day = date.next_day

    # Include one measurement at the end of the day (the first one in the new day)
    end_date = sql_date(DateTime.civil(next_day.year, next_day.month, next_day.day, 1))
    self.where = "WHERE #{adjusted_time_stamp} > #{start_date} AND #{adjusted_time_stamp} < #{end_date}"
    self.granularity = :hour
  end

  def month=(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_month + 1.0 / (24 * 4));
    self.where = "WHERE #{adjusted_time_stamp} > #{start_date} AND #{adjusted_time_stamp} < #{end_date}"
    self.granularity = :day
  end

  def year=(date)
    start_date = sql_date(date)
    end_date = sql_date(date.next_year + 1.0 / (24 * 4));
    self.where = "WHERE #{adjusted_time_stamp} > #{start_date} AND #{adjusted_time_stamp} < #{end_date}"
    self.granularity = :month
  end

  def granularity
    case @granularity
    when :hour
      "YEAR(#{adjusted_time_stamp}), DAYOFYEAR(#{adjusted_time_stamp}), HOUR(#{adjusted_time_stamp})"
    when :day
      "YEAR(#{adjusted_time_stamp}), DAYOFYEAR(#{adjusted_time_stamp})"
    when :month
      "YEAR(#{adjusted_time_stamp}), MONTH(#{adjusted_time_stamp})"
    else
      raise "Unknown granularity for data selection: #{@granularity}"
    end
  end

  protected
  attr_accessor :where
  attr_writer :granularity

  private
  def adjusted_time_stamp
    "time_stamp"
  end

  def sql_date(date)
    %Q|str_to_date('#{date.to_datetime.strftime("%Y-%m-%d %H:%M:%S")}', "%Y-%m-%d %H:%i:%S")|
  end
end
