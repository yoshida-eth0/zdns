require 'socket'
require 'thread'
require 'logger'

module ZDNS
  class Server
    attr_reader :host
    attr_reader :port
    attr_accessor :logger

    def initialize(host="0.0.0.0", port=53)
      @host = host
      @port = port.to_i

      @udp_socket = nil
      @udp_thread = nil

      @tcp_socket = nil
      @tcp_thread = nil
    end

    def logger
      @logger ||= Logger.new(STDOUT)
    end

    def run
      stop

      begin
        # bind udp socket
        @udp_socket = UDPSocket.new
        @udp_socket.bind(host, port)
        logger.info("udp bind: #{host}:#{port}")

        # bind tcp socket
        @tcp_socket = TCPServer.new(host, port)
        logger.info("tcp bind: #{host}:#{port}")
      rescue => e
        logger.error(e)
        stop
        return
      end

      # udp thread
      @udp_thread = Thread.new do
        logger.info("udp server started")
        loop do
          Thread.new(@udp_socket.recvfrom(1024)) do |req_packet_bin, address|
            begin
              # request
              address_family, port, hostname, numeric_address = address
              logger.info("udp request from: #{numeric_address}:#{port}")

              # service
              res_packet = service(req_packet_bin)

              # response
              if res_packet
                res_packet_bin = res_packet.to_bin

                # tcp fallback
                if 512<res_packet_bin.length
                  logger.info("response packet is 512 bytes over. use tcp fallback.")
                  res_packet = Packet.new_from_buffer(req_packet_bin)
                  res_packet.header.response!
                  res_packet.header.tc = Packet::Header::TC::TRUNCATION
                end

                # send
                res_packet_bin = res_packet.to_bin
                @udp_socket.send(res_packet_bin, 0, numeric_address, port)
                logger.info("respond packet: #{res_packet_bin.length} bytes")
              else
                logger.info("skip response packet")
              end
            rescue => e
              logger.error(e)
            end
          end
        end
      end

      # tcp thread
      @tcp_thread = Thread.new do
        logger.info("tcp server started")
        loop do
          Thread.new(@tcp_socket.accept) do |socket|
            begin
              # request
              address_family, port, hostname, numeric_address = socket.addr
              logger.info("tcp request from: #{numeric_address}:#{port}")

              len = socket.read(2).unpack("n")[0]
              req_packet_bin = socket.read(len)

              # service
              res_packet = service(req_packet_bin)

              # response
              if res_packet
                res_packet_bin = res_packet.to_bin
                res_packet_bin = [res_packet_bin.length].pack("n") + res_packet_bin
                socket.send(res_packet_bin, 0)
                logger.info("respond packet: #{res_packet_bin.length} bytes")
              else
                logger.info("skip response packet")
              end
            rescue => e
              logger.error(e)
            ensure
              # close
              socket.close
              logger.info("closed tcp client socket")
            end
          end
        end
      end

      self
    end

    def join
      @udp_thread.join if @udp_thread
      @tcp_thread.join if @tcp_thread
    end

    def stop
      if @udp_thread
        Thread.kill(@udp_thread) rescue nil
        @udp_thread = nil
      end

      if @udp_socket
        @udp_socket.close rescue nil
        @udp_socket = nil
      end

      if @tcp_thread
        Thread.kill(@tcp_thread) rescue nil
        @tcp_thread = nil
      end

      if @tcp_socket
        @tcp_socket.close rescue nil
        @tcp_socket = nil
      end

      self
    end

    def service(packet)
      begin
        packet = Packet.new_from_buffer(packet)
      rescue => e
        logger.error("packet parse error: #{e.class.name}: #{e}")
        return
      end

      if packet.header.query?
        begin
          # lookup
          lookup(packet)

          # header
          if 0<packet.answers.length || 0<packet.authorities.length
            packet.header.aa = Packet::Header::AA::AUTHORITATIVE_ANSWER
            packet.header.rcode = Packet::Header::Rcode::NO_ERROR
          else
            packet.header.rcode = Packet::Header::Rcode::NAME_ERROR
          end

        rescue => e
          logger.error(e)
          packet.header.rcode = Packet::Header::Rcode::SERVER_FAILURE

        ensure
          # header
          packet.header.response!
          packet.header.tc = Packet::Header::TC::NON_TRUNCATION
          packet.header.ra = Packet::Header::RA::RECURSION
          packet.header.qdcount = packet.questions.length
          packet.header.ancount = packet.answers.length
          packet.header.nscount = packet.authorities.length
          packet.header.arcount = packet.additionals.length
        end

        packet
      else
        logger.warning("packet qr is response")
        nil
      end
    end

    def lookup(packet)
      packet.questions.each do |question|
        # answers
        lookup_answers(question).each do |answer|
          packet.answers << answer
        end

        # authorities additionals
        lookup_authorities(question).each do |rrs|
          packet.authorities << rrs
        end
      end
    end

    def lookup_answers(question)
      []
    end

    def lookup_authorities(question)
      []
    end
  end
end
