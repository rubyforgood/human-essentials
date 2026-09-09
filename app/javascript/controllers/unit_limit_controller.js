import { Controller } from "@hotwired/stimulus";

/*
 * Pairs a custom request unit's checkbox with its per-unit request limit.
 *
 * main added the limit in #5386 and wired it with an inline `<script>` in `items/_form`. This app
 * has no inline scripts -- they are unreachable under the CSP and design.md puts behaviour in a
 * Stimulus controller -- so the same rule lives here.
 *
 * The limit is only meaningful for a unit the item actually offers, so it is disabled until the
 * box is ticked. Disabled rather than hidden: the number stays visible, so someone who unticks a
 * unit by accident can see the limit they had typed is still there.
 *
 * Pairing is by DOM order. Each row renders exactly one checkbox and one limit, so
 * `toggleTargets[i]` and `limitTargets[i]` are the same row -- no id arithmetic, which is what
 * main's script did with `id.replace("unit_", "")`.
 */
export default class extends Controller {
  static targets = ["toggle", "limit"]

  connect() {
    this.sync();
  }

  sync() {
    this.toggleTargets.forEach((toggle, i) => {
      const limit = this.limitTargets[i];
      if (limit) limit.disabled = !toggle.checked;
    });
  }
}
