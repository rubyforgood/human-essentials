# see https://discourse.dry-rb.org/t/dry-struct-and-serializer/1517/2
module EventTypes
  class StructCoder
    attr_reader :struct

    def initialize(struct)
      @struct = struct
    end

    def dump(s)
      s.to_hash
    end

    def load(h)
      return if h.nil?
      struct.new(h.with_indifferent_access)
    end
  end
end
