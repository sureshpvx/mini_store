import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["overlay"]

    open() {
        this.overlayTarget.classList.remove("hidden")
        document.body.classList.add("overflow-hidden")
    }

    close() {
        this.overlayTarget.classList.add("hidden")
        document.body.classList.remove("overflow-hidden")

        const form = this.overlayTarget.querySelector("form")
        if (form) form.reset()

        this.clearUploads()
    }

    clearUploads() {
        const uploadControllers = this.overlayTarget.querySelectorAll('[data-controller="upload"]')

        uploadControllers.forEach((el) => {
            const input = el.querySelector('input[type="file"]')
            const preview = el.querySelector('[data-upload-target="preview"]')
            const placeholder = el.querySelector('[data-upload-target="placeholder"]')

            if (input) input.value = ""

            if (preview) {
                preview.innerHTML = ""
                preview.classList.add("hidden")
            }

            if (placeholder) {
                placeholder.classList.remove("hidden")
            }
        })
    }

    stop(e) {
        e.stopPropagation()
    }
}