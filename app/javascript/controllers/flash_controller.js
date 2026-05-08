import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.timeout = setTimeout(() => {
      this.close()
    }, 4000)
  }

  close() {
    this.element.classList.add(
        "opacity-0",
        "translate-x-5",
        "transition-all",
        "duration-300"
    )

    setTimeout(() => {
      this.element.remove()
    }, 300)
  }

  disconnect() {
    clearTimeout(this.timeout)
  }
}