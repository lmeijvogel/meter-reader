#!/usr/bin/env ruby

require 'dotenv'
require 'httparty'

require 'json'

Dotenv.load

class SolarEdgeClient
  include HTTParty

  attr_reader :site_id

  base_uri 'https://monitoringapi.solaredge.com'

  def initialize(site_id, api_key)
    @options = { api_key: api_key }

    @site_id = site_id
  end

  def energy(start_time, end_time)
    formatted_start = start_time.strftime("%Y-%m-%d %H:%M:%S")
    formatted_end = end_time.strftime("%Y-%m-%d %H:%M:%S")

    options = @options.merge({
      startTime: formatted_start,
      endTime: formatted_end,
      timeUnit: "QUARTER_OF_AN_HOUR"

    })
    res = self.class.get("/site/#{site_id}/energyDetails", { query: options })

    res.body
  end
end
