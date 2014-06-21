require 'ostruct'
require_relative '../models/usage.rb'

class DatabaseReader
  def initialize(client)
    @client = client
  end

  def read
    query = "SELECT
      MIN(#{adjusted_time_stamp}) as ts,
      TRUNCATE(MIN(stroom_dal),3) as d_dal,
      TRUNCATE(MIN(stroom_piek),3) as d_piek,
      TRUNCATE(MIN(stroom_piek+stroom_dal),3) as d_totaal,
      TRUNCATE(MAX(gas),3) as d_gas
    FROM measurements
    #{where}
    GROUP BY #{granularity}"

    @client.query(query).map do |row|
      usage = Usage.new
      usage.stroom_dal = row["d_dal"]
      usage.stroom_piek = row["d_piek"]
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
    self.where = "WHERE #{adjusted_time_stamp} > '#{start_date}' AND #{adjusted_time_stamp} < '#{end_date}'"
    self.granularity = :hour
  end

  def week=(date)
    start_date = sql_date(date)
    end_date = sql_date(date + 7)
    self.where = "WHERE #{adjusted_time_stamp} > '#{start_date}' AND #{adjusted_time_stamp} < '#{end_date}'"
    self.granularity = :three_hour
  end

  def month=(date)
    start_date = sql_date(date)
    end_date = date.next_month
    self.where = "WHERE #{adjusted_time_stamp} > '#{start_date}' AND #{adjusted_time_stamp} < '#{end_date}'"
    self.granularity = :day
  end

  def granularity
    case @granularity
    when :hour
      "DAYOFYEAR(#{adjusted_time_stamp}), HOUR(#{adjusted_time_stamp})"
    when :three_hour
      "DAYOFYEAR(#{adjusted_time_stamp}), HOUR(#{adjusted_time_stamp}) DIV 3"
    when :day
      "DAYOFYEAR(#{adjusted_time_stamp})"
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
    date.to_datetime.strftime("%Y-%m-%d %H:%M:%S")
  end
end
