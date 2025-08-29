import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';
import "select2"

export default class extends Controller {
  static values = {
    config: { type: Object, default: {} },
    hideDropdown: { type: Boolean, default: false }
  };

  connect() {
    const select2 = $(this.element).select2(this.configValue);

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
