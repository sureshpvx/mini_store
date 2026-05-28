import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    toggle(event) {
        const button = event.currentTarget
        const item = button.closest("[data-accordion-item]")
        const panel = item.querySelector("[data-accordion-panel]")
        const icon = item.querySelector("[data-accordion-icon]")

        const isHidden = panel.classList.contains("hidden")

        // Close all others (accordion behavior)
        this.element.querySelectorAll("[data-accordion-panel]").forEach((p) => p.classList.add("hidden"))
        this.element.querySelectorAll("[data-accordion-icon]").forEach((i) => i.style.transform = "rotate(0deg)")

        if (isHidden) {
            panel.classList.remove("hidden")
            icon.style.transform = "rotate(180deg)"
        }
    }
}