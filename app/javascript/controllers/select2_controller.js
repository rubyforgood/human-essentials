import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';
import "select2"

export default class extends Controller {
  static values = {
    config: { type: Object, default: {} },
    hideDropdown: { type: Boolean, default: false }
  };

  // select2 replaces the <select> with its own markup, including a search <input> it creates
  // itself. That input inherits no accessible name, so axe reports every select2 on the page as
  // an unlabelled form field. The name is taken from whatever names the original select -- its
  // <label for>, or its own aria-label -- and copied onto the search field.
  //
  // Fixing it here rather than per call site means every select2 in the app gets it, not just
  // the ones an audit happened to visit.
  accessibleName() {
    const id = this.element.id;
    const label = id && document.querySelector(`label[for="${CSS.escape(id)}"]`);
    return (label && label.textContent.trim()) || this.element.getAttribute("aria-label") || null;
  }

  nameSearchFields() {
    const name = this.accessibleName();
    if (!name) return;
    const container = this.element.nextElementSibling;
    if (!container) return;
    container.querySelectorAll("input.select2-search__field").forEach((field) => {
      if (!field.getAttribute("aria-label")) field.setAttribute("aria-label", name);
    });
  }

  connect() {
    // select2 defaults to width: 'resolve', which reads the original select's computed width once
    // and writes it to its own container as pixels. The original is w-full, so on a wide screen
    // that resolves to a wide value and never updates -- measured at 662px inside a 550px parent
    // once the viewport narrowed, overflowing its card. '100%' keeps it fluid.
    //
    // A caller can still override it; this only supplies the default.
    const select2 = $(this.element).select2({ width: "100%", ...this.configValue });

    // The inline search exists once initialised; the dropdown search is created on open.
    this.nameSearchFields();
    $(this.element).on("select2:open", () => {
      requestAnimationFrame(() => {
        const name = this.accessibleName();
        if (!name) return;
        document.querySelectorAll(".select2-container--open input.select2-search__field")
          .forEach((field) => {
            if (!field.getAttribute("aria-label")) field.setAttribute("aria-label", name);
          });
      });
    });

    if (this.hideDropdownValue) {
      select2.on('select2:open', function (e) {
        $('.select2-container--open .select2-dropdown--below').css('display','none');
      });
    }

    /**
     * This is a workaround to auto focus on the select2 input when it is opened.
     */
    $(this.element).on('select2:open', function (e) {
      let select2Instance = $(e.target).data('select2');
      if (select2Instance) {
        let searchField = select2Instance.dropdown.$search || select2Instance.selection.$search;
        if (searchField) {
          searchField.focus();
        }
      }
    });

    /**
     * This is a workaround to prevent select2 from filling in an existing
     * value even when you try to remove everything. This solution was found at
     * https://github.com/select2/select2/issues/3320#issuecomment-1440268574
     */
    if ($(this.element).prop('multiple')) {
      select2.on("select2:unselecting", function (e) {
          $(this).on("select2:opening", function (ev) {
              ev.preventDefault();
              $(this).off("select2:opening");
          });
      });
    }
  }
}
