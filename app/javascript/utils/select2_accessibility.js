/*
 * Names the markup select2 generates.
 *
 * select2 hides the <select> and builds its own combobox and search input beside it. Neither
 * inherits the original's accessible name, so both are reported as unlabelled form fields --
 * and the combobox's own aria-labelledby points at the container holding the *current value*,
 * which is empty until something is chosen.
 *
 * Shared, because select2 is initialised in two controllers. The first version of this lived in
 * select2_controller alone, and the select on /admin/users/new is set up by double_select
 * instead -- so it kept the fault the fix was written for.
 */
export function select2Name(select) {
  const id = select.id;
  const label = id && document.querySelector(`label[for="${CSS.escape(id)}"]`);
  return (label && label.textContent.trim()) || select.getAttribute("aria-label") || null;
}

export function nameSelect2(select) {
  const container = select.nextElementSibling;
  if (!container || !container.classList.contains("select2-container")) return;

  const name = select2Name(select);

  container.querySelectorAll("input.select2-search__field").forEach((field) => {
    if (name && !field.getAttribute("aria-label")) field.setAttribute("aria-label", name);
  });

  // select2 also marks its value display as a readonly textbox. Empty -- nothing chosen yet --
  // that is a form field with no accessible name of its own, which axe reports separately from
  // the combobox around it.
  const rendered = container.querySelector("[role=textbox]");
  if (rendered && name && !rendered.getAttribute("aria-label")) {
    rendered.setAttribute("aria-label", name);
  }

  const combobox = container.querySelector("[role=combobox]");
  if (!combobox) return;

  const id = select.id;
  const label = id && document.querySelector(`label[for="${CSS.escape(id)}"]`);
  if (!label) {
    if (name && !combobox.getAttribute("aria-label")) combobox.setAttribute("aria-label", name);
    return;
  }

  // The label's id goes in FRONT of select2's own container id rather than replacing it, so the
  // control is announced as its name and then its value -- "Resource, Choose a resource" --
  // instead of losing the value announcement that container exists for.
  if (!label.id) label.id = `${id}_label`;
  const existing = (combobox.getAttribute("aria-labelledby") || "").split(/\s+/).filter(Boolean);
  if (existing[0] === label.id) return;
  combobox.setAttribute("aria-labelledby", [label.id, ...existing].join(" "));
}

// The dropdown's search input is created when the menu opens, not at init.
export function nameOpenDropdown(select) {
  const name = select2Name(select);
  if (!name) return;
  document.querySelectorAll(".select2-container--open input.select2-search__field")
    .forEach((field) => {
      if (!field.getAttribute("aria-label")) field.setAttribute("aria-label", name);
    });
}
