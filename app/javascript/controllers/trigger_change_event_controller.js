import { Controller} from "@hotwired/stimulus"

export default class extends Controller {
    connect() {
        this.triggerChangeEvent();
    }

    triggerChangeEvent() {
        if (this.element.value) {
            const event = new Event("change", {bubbles: true});
            this.element.dispatchEvent(event);
        }
    }
}