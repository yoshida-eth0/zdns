require 'zdns/packet/rr/base'
require 'ipaddr'

module ZDNS
  class Packet
    module RR
      class AAAA < Base
        attr_accessor :address

        def type
          Type::AAAA
        end

        def cls
          Class::IN
        end

        def build_rdata(result)
          IPAddr.new(self.address).hton
        end

        class << self
          def parse_rdata(buf)
            {
              :address => buf.read_ipv6,
            }
          end
        end
      end
    end
  end
end
