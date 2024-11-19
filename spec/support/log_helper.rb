def assert_not_logged(message)
  old_logger = ActionController::Base.logger
  log = StringIO.new
  ActionController::Base.logger = Logger.new(log)

  begin
    yield

    log.rewind
    expect(log.read).not_to match(message)
  ensure
    ActionController::Base.logger = old_logger
  end
end
