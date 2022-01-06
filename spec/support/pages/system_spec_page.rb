class SystemSpecPage
  include Capybara::DSL

  def visit
    Capybara.current_session.visit path

    self
  end

  def path
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
