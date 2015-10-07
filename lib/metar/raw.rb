require 'net/ftp'
require 'time'

module Metar

  module Raw

    class Base
      attr_reader :cccc
      attr_reader :metar
      attr_reader :time
      alias :to_s :metar

      def parse
        @cccc = @metar[/\w+/]
      end
    end

    class Data < Base
      def initialize(metar, time = Time.now)
        @metar, @time = metar, time

        parse
      end
    end

    # Collects METAR data from the NOAA site via FTP
    class Noaa < Base

      class << self
        def fetch(cccc)
          ftp_url = 'ftp://tgftp.nws.noaa.gov/data/observations/metar/stations'
          uri = URI(ftp_url)
          raw = StringIO.new('')
          file = "#{cccc}.TXT"
          Net::FTP.open(uri.host) do |ftp|
            ftp.login
            ftp.chdir(uri.path) unless uri.path.empty?
            ftp.binary = true
            ftp.passive = true
            ftp.retrbinary('RETR ' + file, 4096) { |data| raw << data }
            raw.rewind
          end
          raw.string
        rescue
          return ''
        end
      end

      # Station is a string containing the CCCC code, or
      # an object with a 'cccc' method which returns the code
      def initialize(station)
        @cccc = station.respond_to?(:cccc) ? station.cccc : station
      end

      def data
        fetch
        @data
      end
      # #raw is deprecated, use #data
      alias :raw :data

      def time
        fetch
        @time
      end

      def metar
        fetch
        @metar
      end

      private

      def fetch
        return if @data
        @data = Noaa.fetch(@cccc)
        parse
      end

      def parse
        raw_time, @metar = @data.split("\n")
        @time            = Time.parse(raw_time)
        super
      end
    end
  end
end
