import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer"]

  connect() {
    document.addEventListener(
        "turbo:submit-end",
        this.handleTurboSubmit
    )
  }

  disconnect() {
    document.removeEventListener(
        "turbo:submit-end",
        this.handleTurboSubmit
    )
  }

  handleTurboSubmit = (event) => {
    const form = event.target

    if (form.action.includes("/cart/add_item")) {
      this.open()
    }
  }

  open() {
    this.drawerTarget.classList.remove("hidden")

    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.drawerTarget.classList.add("hidden")

    document.body.classList.remove("overflow-hidden")
  }
}