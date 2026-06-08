import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    this.boundDismiss = this.dismiss.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundDismiss)
  }

  toggle(e) {
    e.stopPropagation()
    const isHidden = this.panelTarget.classList.contains("hidden")
    if (isHidden) {
      this.open()
    } else {
      this.close()
    }
  }

  open() {
    this.panelTarget.classList.remove("hidden")
    document.addEventListener("click", this.boundDismiss)
  }

  close() {
    this.panelTarget.classList.add("hidden")
    document.removeEventListener("click", this.boundDismiss)
  }

  dismiss(e) {
    if (!this.element.contains(e.target)) {
      this.close()
    }
  }
}
