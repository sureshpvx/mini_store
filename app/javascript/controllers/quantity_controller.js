import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["input"]

    increment() {
        const max = parseInt(this.inputTarget.max) || Infinity
        let val = parseInt(this.inputTarget.value) || 1
        if (val < max) this.inputTarget.value = val + 1
    }

    decrement() {
        let val = parseInt(this.inputTarget.value) || 1
        if (val > 1) this.inputTarget.value = val - 1
    }
}