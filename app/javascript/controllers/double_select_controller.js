import { Controller } from "@hotwired/stimulus"
import $ from 'jquery';
import "select2"

export default class extends Controller {
  static targets = ['source', 'destination']
  static values = {
    url: String
  }

  sourceChanged() {
    const val = $(this.sourceTarget).val()
    const url = new URL(this.urlValue)
    url.searchParams.append('resource_type', val);
    $(this.destinationTarget).select2({
      ajax: {
        url: url.toString(),
        dataType: 'json'
      }
    });

  }

  connect() {
    /**
     * This is a workaround to auto focus on the select2 input when it is opened.
     */
    $(this.destinationTarget).on('select2:open', function (e) {
      $(".select2-search__field")[0].focus();
    })
    this.sourceChanged();
  }

}
