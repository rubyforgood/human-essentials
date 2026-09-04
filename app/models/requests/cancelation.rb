module Requests
  # The cancellation form's one field, as a record simple_form can attach an error to.
  #
  # The form was `essentials_form_for :cancelation` -- a *symbol*, so there was no object, and
  # therefore no inline error, no `aria-invalid` and no error summary. `form-validation-audit`
  # reported exactly that the first time the route became reachable.
  #
  # It also meant the reason could not be *made* required without losing it: the only way to report
  # a fault was a flash and a redirect, which discards what the user typed. An object lets the
  # action re-render, which is what design.md asks for on a retryable failure.
  #
  # Deliberately not an ActiveRecord model: nothing is stored here, and the reason ends up on the
  # request as `discard_reason`.
  #
  # This is the *only* place the reason is required. `RequestDestroyService` validates states --
  # already cancelled, no such request -- and deliberately not this, because those are failures
  # nobody can retry while a missing reason is one anybody can. One rule, one owner, and the owner
  # is the one that can re-render the form with what was typed still in it. The controller is the
  # service's only caller, checked, so nothing reaches it around this validation.
  class Cancelation
    include ActiveModel::Model

    attr_accessor :reason

    validates :reason, presence: {
      message: "is needed -- the partner is told why their request was cancelled"
    }
  end
end
