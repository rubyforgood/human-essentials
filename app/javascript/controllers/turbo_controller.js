import { Controller } from "@hotwired/stimulus"

/*
 * TurboController is used to handle the Turbo events and to
 * add some custom behavior to the Turbo navigation.
 */
export default class extends Controller {

  /**
   * Scrolls to the top after turbo:submit-end event if the 
   * request was unsuccessful with status code of 4xx or 5xx.
   */
  scrollToTopOnFailedRequest(event) {
    let status = event.detail.fetchResponse.response.status

    if (status >= 400) {
      scrollTo(0, 0)
    }
  }

}
