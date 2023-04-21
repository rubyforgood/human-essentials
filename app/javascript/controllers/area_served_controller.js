import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static targets= ["share", "total", "warning"]
    connect () {
        this.calculateClientShareTotal()
    }
    calculateClientShareTotal ( ){
        let total = 0;
        this.shareTargets.forEach(
            share_target => {
                if ( share_target.value ) {
                    total += parseInt(share_target.value);
                }
            }
        )

        this.totalTarget.innerHTML = total + " %"

        if ( total == 0 || total == 100 ) {
            this.warningTarget.style.visibility = 'hidden';
        } else {
            this.warningTarget.style.visibility = 'visible';
            this.warningTarget.style.color = 'red';
        }
        return total;
    }
}
