// app/javascript/controllers/search_modal_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["overlay", "modal", "input"]

    connect() {
        // Close on Escape key
        document.addEventListener("keydown", (e) => {
            if (e.key === "Escape") this.close()
        })
    }

    open() {
        this.overlayTarget.classList.remove("hidden")
        this.modalTarget.classList.remove("hidden")
        // Small delay for CSS transition
        requestAnimationFrame(() => {
            this.overlayTarget.classList.remove("opacity-0")
            this.modalTarget.classList.remove("-translate-y-2", "opacity-0")
        })
        this.inputTarget.focus()
    }

    close() {
        this.overlayTarget.classList.add("opacity-0")
        this.modalTarget.classList.add("-translate-y-2", "opacity-0")
        setTimeout(() => {
            this.overlayTarget.classList.add("hidden")
            this.modalTarget.classList.add("hidden")
        }, 200)
    }

    // Submit on Enter key
    submitOnEnter(event) {
        if (event.key === "Enter") {
            event.target.form.submit()
        }
    }
}