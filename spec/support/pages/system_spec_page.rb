class SystemSpecPage
  include Capybara::DSL

  def visit
    Capybara.current_session.visit path

    self
  end

  def parse_formatted_integer(str)
    str.delete(",").to_i
  end

  def parse_formatted_currency(str)
    str.delete(",$.").to_i
  end

  def path
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
