import { Controller } from "@hotwired/stimulus"

let delivery_method, shipping_field, shipping_label="";
export default class extends Controller {
    static targets = ["shippingCostField", "shippingCostLabel"]

    connect() {
        delivery_method= $('input[name="distribution[delivery_method]"]:checked')[0].value;
        this.toggle(delivery_method);
    }

    toggleShippingCost(e) {
         delivery_method = e.target.value;
         this.toggle(delivery_method);
    }

    toggle(selected_delivery_method) {
        shipping_field = this.shippingCostFieldTarget;
        shipping_label = this.shippingCostLabelTarget;

        if (selected_delivery_method == "shipped")
        {
            shipping_field.classList.remove("d-none");
            shipping_label.classList.remove("d-none");
        }
        else
        {
            shipping_field.classList.add("d-none");
            shipping_label.classList.add("d-none");
        }
    }
}