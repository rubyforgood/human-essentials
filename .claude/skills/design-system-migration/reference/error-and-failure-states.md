# Error and failure states

What a screen does when something goes wrong is the part least likely to have been designed and most
likely to have been copied. Every rule here came from a defect found in a real app, and each is
**Portable** unless marked otherwise.

## Ask what the user should do next, and send them there

Re-rendering the form is right when the user can change something and try again. It is wrong when
the failure is a **state** — the record is already gone, already cancelled, already claimed by
somebody else. Returning them to the form then puts them in front of a control that can never
succeed, and discards whatever they had typed into it.

A cancellation screen failed only on "we could not find it" and "it has already been cancelled",
and redirected back to its own form with a flash. Someone whose colleague cancelled the record first
would write their reason again and get the same error, forever. The fix was the destination, not the
message: the record's own page, which shows the state that actually applies.

> Sort your failures into **retryable** and **not**. Retryable re-renders. Not-retryable goes
> somewhere that reflects reality — and if the answer to "what should they do now" is "nothing, it
> is already done", the form is the one place they should not be.

Watch the fallback too: sending them to the record's page when the record does not exist answers a
failure with a 404.

## Operational failure gets the flash; validation failure gets the summary; never both

Two live regions for one event get announced twice and usually disagree about what happened. One app
had this on **18 forms**, where the summary said "Storage location must exist" and the flash said
something generic.

Use a helper that sets the flash **only when the record carries no errors** — the case a flash is
genuinely for: a service raised, or a business rule failed without attaching anything to the record.

## The summary takes focus; the live region goes inside it

`role="alert"` is not enough on its own, and this is the part people get wrong.

**A live region is defined in terms of a subtree changing.** If the failed submit re-renders the
whole page, the summary is already in the markup when the accessibility tree is first built —
nothing changed, and whether it is announced varies by screen reader. Focus does not depend on that
timing, and it also puts a keyboard user *at* the errors instead of at the top of a document that
looks like the one they just sent.

So: `tabindex="-1"` on the summary container, focused on load. Two details that are easy to miss:

- **Put the live region inside the focused element, not on it.** Focusing something that is itself
  `role="alert"` reads its contents twice on several screen reader and browser pairings. The focused
  container is a plain element; the role sits on a wrapper within it.
- **Take focus only from nothing.** Return early unless the active element is the body. If a summary
  can ever arrive in a partial page update while somebody is typing, stealing the caret loses their
  place, and an accessibility fix that interrupts people is not one.

Give it your ordinary focus ring. Browsers may match `:focus-visible` on programmatic focus and
paint their own default; the moment focus has been moved *for* someone is exactly when they need to
see where it went.

## A shared error component must not name fields the page does not have

Where one component is rendered by several forms, the standing advice above the specific errors
belongs to the **caller** — only the caller knows what it is asking for. Pass it in, default to the
common case.

One partial told three forms "every line needs an item selected and a quantity greater than zero".
True of two of them. The third's only controls were checkboxes, so a user who submitted with nothing
selected was told to check the quantity on lines that were not on the screen.

**Test it with the negative assertion.** `expect(page).not_to include(<the other form's sentence>)`
is what catches a regression; the positive assertion passes just as happily with the default
restored, because the specific error underneath never changed.

## Do not mark a field required unless something enforces it

A label asterisk and `aria-required="true"` with no validation behind them is a promise the form does
not keep. Decide which way it goes — genuinely required, or genuinely optional — and make the markup
and the server agree. Both are defensible; the mismatch is not.

## One concept gets one rendering, and a helper is where that is enforced

When the same state appears on two screens, two views drift — and they drift in meaning, not just in
styling.

An invitation status was plain lowercase text in one table and coloured pills in another. They did
not merely look different: the model distinguished *accepted* (took the invitation) from *joined*
(has signed in since), and the second screen recomputed the state from one timestamp and collapsed
both. The same user read "joined" on one screen and "Accepted" on the other.

When you find two renderings of one concept, the question is not "which looks better" but **which
carries more information** — then put it in a helper both call.

## Errors written for developers reach users verbatim

Model and service messages get interpolated straight into a flash or a bullet list. Read them as a
user would: `"completely empty request"`, `"request_id is invalid"`, `"detected a unknown item_id"`.

When a message is exercised by specs asserting its exact string, changing it is a small mechanical
cost and worth paying — but check the blast radius first, and say so if you leave one alone. A raw
string that is documented is much cheaper than one that is a surprise.
