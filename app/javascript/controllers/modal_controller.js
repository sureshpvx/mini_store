import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["overlay"]

    open(event) {
        const modalId = event.currentTarget.dataset.modalId

        const modal = document.getElementById(modalId)

        modal.classList.remove("hidden")

        document.body.classList.add("overflow-hidden")
    }

    close(event) {
        const modal = event.currentTarget.closest("[id]")

        modal.classList.add("hidden")

        document.body.classList.remove("overflow-hidden")

        const form = modal.querySelector("form")

        if (form) form.reset()

        this.clearUploads(modal)
    }

    clearUploads(modal) {
        const uploadControllers =
            modal.querySelectorAll('[data-controller="upload"]')

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