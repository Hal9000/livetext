  class Livetext::Variables      # FIXME - split out into file as Livetext::Variables
    attr_reader :vars

    def initialize(hash = {})   # Livetext::Variables
      @vars = {}
      hash.each_pair do |k, v| 
        sym = k.to_sym
        str = k.to_s
        @vars[sym] = v 
        @vars[str] = v 
      end
    end

    def inspect
      syms = @vars.keys.select {|x| x.is_a? Symbol }
      out = "\nVariables:"
      syms.each do |sym|
        out << "    #{sym}: #{@vars[sym].inspect}\n"
      end
      out
    end
  
    def [](var)
      @vars[var.to_sym] || "[#{var} is undefined]"
    end

    def []=(var, value)
      @vars[var.to_sym] = value
    end

    def get(var)
      @vars[var.to_sym] || "[#{var} is undefined]"
    end

    def set(var, value)
      @vars[var.to_sym] = value.to_s
    end

    def setvars(pairs)
      pairs = pairs.to_a if pairs.is_a?(Hash)
      pairs.each do |var, value|
        api.setvar(var, value)
      end
    end

    def to_a
      @vars.to_a
    end

    def to_h
      @vars.select { |k, v| k.is_a?(Symbol) }
    end

    def exists?(var)
      @vars[var.to_sym] != nil
    end
  end

