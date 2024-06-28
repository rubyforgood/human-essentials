import { Controller } from "@hotwired/stimulus"
import { post } from "@rails/request.js"

export default class extends Controller {
  update_units() {
    const item_id = this.element.value
    console.log(item_id)
    post(`/items/${item_id}/request_units`, {
      query: { item_id },
      responseKind: 'turbo-stream'
    })
  }
}
