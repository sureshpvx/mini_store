
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]

  connect() {
    this.showTab(0)
  }

  switch(event) {
    const index = parseInt(event.currentTarget.dataset.index)
    this.showTab(index)
  }

  showTab(index) {
    this.tabTargets.forEach((tab, i) => {
      const isActive = i === index
                            tab.classList.toggle("text-black", isActive)
    tab.classList.toggle("border-black", isActive)
    tab.classList.toggle("text-gray-400", !isActive)
    tab.classList.toggle("border-transparent", !isActive)
  })

  this.panelTargets.forEach((panel, i) => {
    panel.classList.toggle("hidden", i !== index)
  })
}
}