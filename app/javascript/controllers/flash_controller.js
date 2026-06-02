// app/javascript/controllers/flash_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    timeout: { type: Number, default: 4000 }
  }

  connect() {
    this.timeoutId = setTimeout(() => this.close(), this.timeoutValue)
  }

  close() {
    this.element.classList.add("opacity-0", "translate-x-5", "transition-all", "duration-300")
    setTimeout(() => this.element.remove(), 300)
  }

  disconnect() {
    clearTimeout(this.timeoutId)
  }
}