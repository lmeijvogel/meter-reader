require 'ostruct'
require_relative '../models/usage.rb'

class DatabaseReader
  def initialize(client)
    @client = client
  end

  def read
    query = "SELECT
      MIN(#{adjusted_time_stamp}) as ts,
      TRUNCATE(MAX(stroom_dal)-MIN(stroom_dal),3) as d_dal,
      TRUNCATE(MAX(stroom_piek)-MIN(stroom_piek),3) as d_piek,
      TRUNCATE(MAX(stroom_piek+stroom_dal)-MIN(stroom_piek+stroom_dal),3) as d_totaal,
      TRUNCATE(MAX(gas)-MIN(gas),3) as d_gas
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
    date = date.to_datetime
    self.where = "WHERE #{adjusted_time_stamp} > '#{date}' AND #{adjusted_time_stamp} < '#{date.next_day}'"
    self.granularity = :hour
  end

  def week=(date)
    date = date.to_datetime
    self.where = "WHERE #{adjusted_time_stamp} > '#{date}' AND #{adjusted_time_stamp} < '#{date + 7}'"
    self.granularity = :three_hour
  end

  def month=(date)
    date = date.to_datetime
    self.where = "WHERE #{adjusted_time_stamp} > '#{date}' AND #{adjusted_time_stamp} < '#{date.next_month}'"
    self.granularity = :three_hour
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
end
