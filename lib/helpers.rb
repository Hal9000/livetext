
module Helpers

  def check_disallowed(name)
    # raise "Illegal name '#{name}'" if _disallowed?(name)
    # FIXME use custom exception
    raise DisallowedName, name if _disallowed?(name)
  end

  def check_file_exists(file)
    raise FileNotFound(file) unless File.exist?(file)
  end

  def set_variables(pairs)
    pairs.each do |pair|
      var, value = *pair
      @parent._setvar(var, value)
    end
  end

  def grab_file(fname)
    File.read(fname)
  end

end
