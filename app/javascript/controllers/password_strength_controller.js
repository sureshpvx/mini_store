import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "checklist", "ruleLength", "ruleUppercase", "ruleLowercase", "ruleNumber", "ruleSpecial"]

  connect() {
    this.blurTimeout = null
    this.rules = [
      { target: "ruleLength",    test: v => v.length >= 6 },
      { target: "ruleUppercase", test: v => /[A-Z]/.test(v) },
      { target: "ruleLowercase", test: v => /[a-z]/.test(v) },
      { target: "ruleNumber",    test: v => /[0-9]/.test(v) },
      { target: "ruleSpecial",   test: v => /[!@#$%^&*]/.test(v) },
    ]
  }

  disconnect() {
    if (this.blurTimeout) clearTimeout(this.blurTimeout)
  }

  // ── Show checklist on focus ──
  show() {
    if (this.blurTimeout) {
      clearTimeout(this.blurTimeout)
      this.blurTimeout = null
    }
    const panel = this.checklistTarget
    panel.classList.remove("hidden")
    // Trigger reflow so the transition plays
    requestAnimationFrame(() => {
      panel.style.maxHeight = panel.scrollHeight + "px"
      panel.style.opacity = "1"
    })
  }

  // ── Hide checklist on blur (with delay to avoid flicker) ──
  hide() {
    this.blurTimeout = setTimeout(() => {
      const panel = this.checklistTarget
      panel.style.maxHeight = "0px"
      panel.style.opacity = "0"
      // Hide from DOM after transition completes
      panel.addEventListener("transitionend", () => {
        if (panel.style.maxHeight === "0px") {
          panel.classList.add("hidden")
        }
      }, { once: true })
    }, 200)
  }

  // ── Validate each rule on every keystroke ──
  validate() {
    const value = this.inputTarget.value

    this.rules.forEach(rule => {
      const el = this[`${rule.target}Target`]
      const passed = rule.test(value)
      const icon = el.querySelector("[data-icon]")
      const text = el.querySelector("[data-text]")

      if (passed) {
        icon.innerHTML = this.checkedSVG
        text.classList.remove("text-gray-400")
        text.classList.add("text-emerald-600")
        el.classList.add("ps-rule-passed")
      } else {
        icon.innerHTML = this.uncheckedSVG
        text.classList.remove("text-emerald-600")
        text.classList.add("text-gray-400")
        el.classList.remove("ps-rule-passed")
      }
    })
  }

  // ── SVG icons ──
  get uncheckedSVG() {
    return `<svg class="w-4 h-4 text-gray-300 shrink-0" viewBox="0 0 20 20" fill="none" stroke="currentColor" stroke-width="1.5">
      <circle cx="10" cy="10" r="8"/>
    </svg>`
  }

  get checkedSVG() {
    return `<svg class="w-4 h-4 text-emerald-500 shrink-0" viewBox="0 0 20 20" fill="none">
      <circle cx="10" cy="10" r="8" fill="currentColor" opacity="0.15"/>
      <circle cx="10" cy="10" r="8" stroke="currentColor" stroke-width="1.5" fill="none"/>
      <path d="M6.5 10.5L9 13L14 7" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
    </svg>`
  }
}
