import { Controller } from "@hotwired/stimulus"

// A tag input: type a word, press Enter, get a chip.
//
// Replaces select2 in free-tagging mode on this field. That control looked like a select, so the
// first thing anyone did was click it expecting a list -- and its dropdown was hidden, so nothing
// opened and nothing on screen said the interaction was "type, then comma". Its chips were
// select2's own #aaa/#e4e4e4, which appear nowhere else in this design system, and the remove
// target measured 9x21 against WCAG 2.5.8's 24x24.
//
// **The <select multiple> is still the field.** It is what submits, so the wire format is
// unchanged -- `name[]` repeated, exactly what select2 sent. The controller keeps it in sync and
// hides it only once the chip UI exists, gated on `data-tag-input="ready"`, which is the same
// arrangement the table rail uses: with no JavaScript the native multi-select is exactly as it was.
export default class extends Controller {
  static targets = ["source", "box", "input", "chips", "status"]

  connect() {
    this.render()
    this.element.dataset.tagInput = "ready"
  }

  // Adding on Enter rather than only on comma, because Enter is what every tag input does and
  // comma is what nothing announces. Comma and Tab still work -- they were the old separators, so
  // anyone with the habit keeps it.
  keydown(event) {
    if (event.key === "Enter" || event.key === ",") {
      event.preventDefault()
      this.commit()
    } else if (event.key === "Backspace" && this.inputTarget.value === "") {
      const values = this.values
      if (values.length) this.remove(values[values.length - 1])
    }
  }

  // Tab and clicking away commit what has been typed, so a half-entered unit is not silently lost
  // -- select2's `selectOnClose` did this and losing it would be a regression.
  blur() {
    this.commit()
  }

  paste(event) {
    const text = (event.clipboardData || window.clipboardData).getData("text")
    if (!text.includes(",") && !text.includes("\t")) return
    event.preventDefault()
    text.split(/[,\t\n]/).forEach((part) => this.add(part))
  }

  commit() {
    if (this.add(this.inputTarget.value)) this.inputTarget.value = ""
  }

  add(raw) {
    const value = raw.trim()
    if (!value) return false
    // Case-insensitive, so "Pack" cannot join "pack" as a second unit. The old control allowed it.
    if (this.values.some((v) => v.toLowerCase() === value.toLowerCase())) {
      this.announce(`${value} is already in the list`)
      this.inputTarget.value = ""
      return false
    }
    const option = new Option(value, value, true, true)
    this.sourceTarget.add(option)
    this.render()
    this.announce(`${value} added`)
    return true
  }

  remove(value) {
    ;[...this.sourceTarget.options].forEach((option) => {
      if (option.value === value) option.remove()
    })
    this.render()
    this.announce(`${value} removed`)
    this.inputTarget.focus()
  }

  get values() {
    return [...this.sourceTarget.options].filter((o) => o.selected).map((o) => o.value)
  }

  render() {
    this.chipsTarget.replaceChildren(...this.values.map((value) => this.chip(value)))
  }

  chip(value) {
    const chip = document.createElement("span")
    chip.className = "inline-flex min-h-7 items-center gap-1 rounded-md border border-brand-200 " +
      "bg-brand-50 py-0.5 pl-2 pr-0.5 text-sm font-medium text-brand-700"
    chip.append(value)

    const remove = document.createElement("button")
    remove.type = "button"
    // 24x24, so it meets WCAG 2.5.8 outright rather than relying on the spacing exception --
    // against the 9x21 select2 gave it, which met neither.
    remove.className = "inline-flex size-6 items-center justify-center rounded text-brand-600 " +
      "hover:bg-brand-100 hover:text-brand-800 focus-visible:outline-2 focus-visible:outline-offset-1 " +
      "focus-visible:outline-brand-600"
    remove.setAttribute("aria-label", `Remove ${value}`)
    // A chip's x is named but carries no tooltip: the label it removes is right beside it. Declared
    // rather than left for the tooltip audit to guess -- see the note there.
    remove.setAttribute("data-chip-dismiss", "")
    remove.innerHTML = '<i class="bi-x-lg text-[0.625rem]" aria-hidden="true"></i>'
    remove.addEventListener("click", () => this.remove(value))

    chip.append(remove)
    return chip
  }

  // Chips appear and disappear without focus moving, so nothing would otherwise be announced.
  announce(message) {
    if (this.hasStatusTarget) this.statusTarget.textContent = message
  }

}
