require 'nagios-plugin'
require 'json'

require "nagios_cgminer/version"

module NagiosCgminer
  class Plugin < Nagios::Plugin
    def run
      @cgminer_port = 4028

      @opts.banner = "Usage: nagios_cgminer [options] CGMINER_URL"
      @opts.on("-P", "--port 4028", "Port of cgminer API") do |port|
        @cgminer_port = port
      end
      @opts.parse!

      @cgminer_url = ARGV[0]
      unless @cgminer_url
        puts @opts.help
        exit(255)
      end
      @critical &&= @critical.to_f
      @warning &&= @warning.to_f

      socket = Socket.new Socket::AF_INET, Socket::SOCK_STREAM
      socket.connect(Socket.pack_sockaddr_in(@cgminer_port, @cgminer_url))
      socket.send(JSON.generate({command: "summary"}), 0)
      message = ""
      while (more = socket.recv(4096)) != ""
        message += more
      end
      summary = JSON.parse(message.strip)

      average_hashrate = summary['SUMMARY'][0]['MHS av'].to_f
      pool = "Unknown"
      message = "Speed: #{average_hashrate}; Pool: #{pool}"
      if average_hashrate < @critical
        critical(message)
      elsif average_hashrate < @warning
        warning(message)
      else
        ok(message)
      end
    end

    def cgminer_full_api_url
      "#{@cgminer_url}:#{@cgminer_port}"
    end
  end
end
