import { Controller } from "@hotwired/stimulus"

/*
 * TurboController is used to handle the Turbo events and to
 * add some custom behavior to the Turbo navigation.
 */
export default class extends Controller {

  connect() {

    /**
     * Scrolls to the top after turbo:submit-end event if the
     * request was unsuccessful with status code of 4xx or 5xx.
     */
    document.addEventListener("turbo:submit-end", (event) => {
      if (!event.detail.success) {
        scrollTo(0, 0);
      }
    })
  }
}
