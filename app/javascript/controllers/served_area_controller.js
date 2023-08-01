import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
    static targets= ["share"]

    connect(){}
    zeroShareValue(){
        let share_target = this.shareTarget
        share_target.value = 0
    }

}