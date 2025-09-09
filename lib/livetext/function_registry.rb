# Function Registry - Unified function management for Livetext
class Livetext::FunctionRegistry
  def initialize
    @user_functions = {}
    @builtin_functions = {}
    @metadata = {}
    register_builtin_functions
    # puts "DEBUG: Registered #{@builtin_functions.size} builtin functions" if ENV['DEBUG']
  end
  
  def register_user(name, function, source: :inline, filename: nil)
    name_sym = name.to_sym
    @user_functions[name_sym] = function
    @metadata[name_sym] = { source: source, filename: filename }
  end
  
  def register_builtin(name, function)
    @builtin_functions[name] = function
    @metadata[name] = { source: :builtin, filename: "builtin" }
  end
  
  def call(name, param)
    # Convert name to symbol for consistent lookup
    name_sym = name.to_sym
    
    if @user_functions[name_sym]
      call_function(name, @user_functions[name_sym], param)
    elsif @builtin_functions[name_sym]
      call_function(name, @builtin_functions[name_sym], param)
    else
      # Fall back to Livetext::Functions for backward compatibility
      fobj = ::Livetext::Functions.new
      if fobj.respond_to?(name_sym)
        method = fobj.method(name_sym)
        if method.parameters.empty?
          result = fobj.send(name_sym)
        else
          result = fobj.send(name_sym, param)
        end
        return result.to_s if result
      end
      
      "[Error evaluating $$#{name}(#{param})]"
    end
  end
  
           def list_functions
           result = []
           @user_functions.each { |name, _| result << { name: name.to_s, source: get_source(name) } }
           @builtin_functions.each { |name, _| result << { name: name.to_s, source: get_source(name) } }
           result.sort_by { |f| f[:name] }
         end
         
         def get_function_info(name)
           name_sym = name.to_sym
           metadata = @metadata[name_sym]
           return nil unless metadata
           
           {
             name: name.to_s,
             source: get_source(name),
             filename: metadata[:filename],
             type: @user_functions.key?(name_sym) ? :user : :builtin
           }
         end
  
  def function_exists?(name)
    name_sym = name.to_sym
    @user_functions.key?(name_sym) || @builtin_functions.key?(name_sym)
  end
  
  private
  
  def call_function(name, function, param)
    function.call(param)
  rescue => e
    "[Error evaluating $$#{name}(#{param})]"
  end
  
  def get_source(name)
    name_sym = name.to_sym
    metadata = @metadata[name_sym]
    case metadata[:source]
    when :inline then "inline (#{metadata[:filename] || 'unknown'})"
    when :mixin then "mixin (#{metadata[:filename] || 'unknown'})"
    when :builtin then "builtin"
    else "unknown"
    end
  end
  
  def register_builtin_functions
    # Move all current Livetext::Functions methods here
    register_builtin(:date, ->(param) { Time.now.strftime("%F") })
    register_builtin(:time, ->(param) { Time.now.strftime("%T") })
    register_builtin(:pwd, ->(param) { Dir.pwd })
    register_builtin(:rand, ->(param) do
      if param && !param.empty?
        n1, n2 = param.split.map(&:to_i)
        Kernel.rand(n1..n2).to_s
      else
        Kernel.rand.to_s
      end
    end)
    register_builtin(:link, ->(param) do
      if param && param.include?("|")
        text, url = param.split("|", 2)
        "<a style='text-decoration: none' href='#{url}'>#{text}</a>"
      else
        "[Error in function $$link: expected 'text|url' format]"
      end
    end)
    register_builtin(:br, ->(param) do
      n = (param && !param.empty?) ? param.to_i : 1
      "<br>" * n
    end)
    register_builtin(:reverse, ->(param) do
      if param && !param.empty?
        param.reverse
      else
        "(reverse: No parameter)"
      end
    end)
    register_builtin(:isqrt, ->(param) do
      arg = num = param
      if num.nil? || num.empty?
        arg = "NO PARAM"
      end
      num = num.include?(".") ? Float(num) : Integer(num)
      Math.sqrt(num).to_i.to_s
    rescue => err
      "[Error evaluating $$isqrt(#{arg})]"
    end)
    
    # System info functions (return current values)
    register_builtin(:hostname, ->(param) { `hostname`.chomp })
    register_builtin(:platform, ->(param) { RUBY_PLATFORM })
    register_builtin(:ruby_version, ->(param) { RUBY_VERSION })
    register_builtin(:livetext_version, ->(param) { Livetext::VERSION })
    
    # Date/time functions
    register_builtin(:year, ->(param) { Time.now.year.to_s })
    register_builtin(:month, ->(param) { Time.now.mon.to_s })
    register_builtin(:day, ->(param) { Time.now.day.to_s })
    register_builtin(:hour, ->(param) { Time.now.hour.to_s })
    register_builtin(:minute, ->(param) { Time.now.min.to_s })
    register_builtin(:second, ->(param) { Time.now.sec.to_s })
    register_builtin(:weekday, ->(param) { Time.now.wday.to_s })
    register_builtin(:week, ->(param) { Time.now.strftime("%U") })
    
    # Date formatting functions
    register_builtin(:format_date, ->(param) do
      if param && !param.empty?
        Time.now.strftime(param)
      else
        Time.now.strftime("%F") # Default format
      end
    end)
    register_builtin(:days_ago, ->(param) do
      if param && !param.empty?
        days = param.to_i
        (Time.now - (days * 24 * 60 * 60)).strftime("%F")
      else
        "[Error evaluating $$days_ago: requires number of days]"
      end
    end)
    register_builtin(:days_from_now, ->(param) do
      if param && !param.empty?
        days = param.to_i
        (Time.now + (days * 24 * 60 * 60)).strftime("%F")
      else
        "[Error evaluating $$days_from_now: requires number of days]"
      end
    end)
  end
end
