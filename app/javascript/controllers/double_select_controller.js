import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';
import "select2"
import { nameSelect2, nameOpenDropdown } from "utils/select2_accessibility"

export default class extends Controller {
  static targets = ['source', 'destination']
  static values = {
    url: String
  }

  sourceChanged() {
    const val = $(this.sourceTarget).val()
    const url = new URL(this.urlValue)
    url.searchParams.append('resource_type', val);
    $(this.destinationTarget).empty().val(null).trigger('change');
    $(this.destinationTarget).select2({
      ajax: {
        url: url.toString(),
        dataType: 'json'
      }
    });
    // select2 rebuilds its markup here, so the names have to be reapplied.
    nameSelect2(this.destinationTarget);

  }

  connect() {
    /**
     * This is a workaround to auto focus on the select2 input when it is opened.
     */
    $(this.destinationTarget).on('select2:open', () => {
      nameOpenDropdown(this.destinationTarget);
      $(".select2-search__field")[0].focus();
    })
    this.sourceChanged();
  }

}
