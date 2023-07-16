require "json"
class LogFormatter
  def call(data)
    ::JSON.dump({message: data})
  end
end
