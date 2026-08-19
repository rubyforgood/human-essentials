# Waiting for a filter to apply.
#
# Filter bars have no Filter button: they apply on change, into a Turbo Frame. That removes the
# click a spec used to synchronise on, so an assertion made straight after `select` races the
# swap, and fails in two ways that both look like a broken expectation rather than a timing
# problem: Capybara reads the rows that were already there, or a node goes stale mid-query while
# the frame is replaced and Cuprite reports it in the match list as "<<ERROR>>".
#
# Waiting on the frame's `busy` attribute does not work. Turbo only marks a frame busy when its
# own controller handles the navigation; these forms sit *outside* the frame they target and the
# frames carry `target="_top"`, so the submit is handled by the session instead and the attribute
# is never set. Measured: the request fires at +11ms and the frame renders at +93ms, with no
# attribute mutation at any point.
#
# Network idle is the signal that does hold. The quiet period has to be longer than the gap
# between the change event and the request leaving, or "idle" is satisfied by the moment before
# anything has started.
module FilterHelpers
  FILTER_QUIET_PERIOD = 0.3

  def wait_for_filters
    page.driver.wait_for_network_idle(duration: FILTER_QUIET_PERIOD, timeout: 10)
  rescue Ferrum::TimeoutError
    # Ten seconds of continuous traffic is not a filter still applying; let the assertion that
    # follows report what is actually on the page.
    nil
  end
end

RSpec.configure do |config|
  config.include FilterHelpers, type: :system
end
