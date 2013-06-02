require 'zdns/packet/rr/base'

module ZDNS
  class Packet
    module RR
      class NS < Base
        attr_accessor :nsdname

        def type
          Type::NS
        end

        def cls
          Class::IN
        end

        def build_rdata(result)
          compress_domain(result, self.nsdname)
        end

        class << self
          def parse_rdata(buf)
            {
              :nsdname => buf.read_name,
            }
          end
        end
      end
    end
  end
end
