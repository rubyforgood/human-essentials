import { Controller } from "@hotwired/stimulus"

let delivery_method, shipping_cost_div="";
export default class extends Controller {
    static targets = ["shippingCost"]

    connect() {
        delivery_method= $('input[name="distribution[delivery_method]"]:checked')[0].value;
        this.toggle(delivery_method);
    }

    toggleShippingCost(e) {
         delivery_method = e.target.value;
         this.toggle(delivery_method);
    }

    toggle(selected_delivery_method) {
        // `hidden`, not Bootstrap's `d-none`, which is no longer defined.
        this.shippingCostTarget.classList.toggle("hidden", selected_delivery_method != "shipped");
    }
}