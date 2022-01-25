# Reopen for convenience... do differently

class Object
  def send?(meth, *args)
    if self.respond_to?(meth)
      self.send(meth, *args)
    else
      return nil
    end
  end
end

