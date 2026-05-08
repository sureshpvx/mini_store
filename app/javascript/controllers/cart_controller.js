import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["drawer"]

  open() {
    this.drawerTarget.classList.remove("hidden")

    document.body.classList.add("overflow-hidden")
  }

  close() {
    this.drawerTarget.classList.add("hidden")

    document.body.classList.remove("overflow-hidden")
  }
}