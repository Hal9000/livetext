class Livetext::Functions    # Functions will go here... user-def AND pre-def??
  def date
    Time.now.strftime("%F")
  end

  def time
    Time.now.strftime("%T")
  end
end
