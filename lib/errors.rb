
# More later?

def make_exception(sym, str, target_class = Object)
  return if target_class.constants.include?(sym)
  target_class.const_set(sym, StandardError.dup)
  define_method(sym) do |*args|
    msg = str.dup
    args.each.with_index {|arg, i| msg.sub!("%#{i+1}", arg) }
    target_class.class_eval(sym.to_s).new(msg)
  end
end

