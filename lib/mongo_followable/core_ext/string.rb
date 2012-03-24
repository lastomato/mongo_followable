class String
  if defined? safe_capitalize
    alias safe_capitalize_original safe_capitalize
  end

  def capitalized?
    self[0].ord > 64 && self[0].ord < 91
  end

  def safe_capitalize
    if self.include? "_"
      self.split("_").map(&:capitalize).join
    elsif self[0].capitalized?
      self
    else
      self.capitalize
    end
  end
end