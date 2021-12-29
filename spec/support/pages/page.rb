module Page
  include Capybara::DSL

  def visit
    page.visit path

    self
  end

  def path
    raise NotImplementedError, "This #{self.class} cannot respond to:"
  end
end
