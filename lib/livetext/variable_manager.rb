# Variable Manager - Centralized variable handling for Livetext
class Livetext::VariableManager
  def initialize(parent)
    @parent = parent
    @variables = Livetext::Variables.new
    initialize_default_variables
  end

  def set(name, value)
    @variables.set(name, value)
  end

  def get(name)
    @variables.get(name)
  end

  def [](name)
    @variables[name]
  end

  def set_multiple(pairs)
    pairs.each do |name, value|
      set(name, value)
    end
  end

  def exists?(name)
    @variables.exists?(name)
  end

  def list
    @variables.inspect
  end

  def to_h
    @variables.to_h
  end

  def replace(vars)
    @variables = Livetext::Variables.new(vars)
  end

  # Enable live.vars.myvar syntax
  def method_missing(name, *args)
    if args.empty?
      @variables[name.to_sym] || "[#{name} is undefined]"
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    true  # Since method_missing always returns a value, respond_to? should always return true
  end

  private

  def initialize_default_variables
    # System info variables
    set(:User, `whoami`.chomp)
    set(:Version, Livetext::VERSION)
    set(:Hostname, `hostname`.chomp)
    set(:Platform, RUBY_PLATFORM)
    set(:RubyVersion, RUBY_VERSION)
    set(:LivetextVersion, Livetext::VERSION)
    
    # Date/time variables
    now = Time.now
    set(:Year, now.year.to_s)
    set(:Month, now.mon.to_s)
    set(:Day, now.day.to_s)
    set(:Hour, now.hour.to_s)
    set(:Minute, now.min.to_s)
    set(:Second, now.sec.to_s)
    set(:Weekday, now.wday.to_s)
    set(:Week, now.strftime("%U"))
  end
end
