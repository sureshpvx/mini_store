import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["timer", "button", "display"]
    static values = { remaining: Number }

    connect() {
        this.remaining = this.remainingValue

        if (this.remaining > 0) {
            this.tick()
            this.interval = setInterval(() => {
                this.remaining--
                this.tick()
                if (this.remaining <= 0) this.showButton()
            }, 1000)
        } else {
            this.showButton()
        }
    }

    tick() {
        const m = Math.floor(this.remaining / 60).toString().padStart(2, "0")
        const s = (this.remaining % 60).toString().padStart(2, "0")
        this.displayTarget.textContent = `${m}:${s}`
    }

    showButton() {
        clearInterval(this.interval)
        this.timerTarget.classList.add("hidden")
        this.buttonTarget.classList.remove("hidden")
    }

    disconnect() {
        clearInterval(this.interval)
    }
}