import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "checklist", "ruleLength", "ruleUppercase", "ruleLowercase", "ruleNumber", "ruleSpecial", "toggle", "eyeIcon"]

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
    if (!this.hasChecklistTarget) return
    if (this.blurTimeout) {
      clearTimeout(this.blurTimeout)
      this.blurTimeout = null
    }
    const panel = this.checklistTarget
    panel.classList.remove("hidden")
    requestAnimationFrame(() => {
      panel.style.maxHeight = panel.scrollHeight + "px"
      panel.style.opacity = "1"
    })
  }

  // ── Hide checklist on blur (with delay to avoid flicker) ──
  hide() {
    if (!this.hasChecklistTarget) return
    this.blurTimeout = setTimeout(() => {
      const panel = this.checklistTarget
      panel.style.maxHeight = "0px"
      panel.style.opacity = "0"
      panel.addEventListener("transitionend", () => {
        if (panel.style.maxHeight === "0px") {
          panel.classList.add("hidden")
        }
      }, { once: true })
    }, 200)
  }

  // ── Validate each rule on every keystroke ──
  validate() {
    if (!this.hasChecklistTarget) return
    const value = this.inputTarget.value

    this.rules.forEach(rule => {
      const targetName = `${rule.target}Target`
      if (!this[`has${rule.target.charAt(0).toUpperCase() + rule.target.slice(1)}Target`]) return

      const el = this[targetName]
      const passed = rule.test(value)
      const icon = el.querySelector("[data-icon]")
      const text = el.querySelector("[data-text]")

      if (passed) {
        icon.innerHTML = this.checkedSVG
        text.classList.remove("text-gray-400")
        text.classList.add("text-emerald-600")
      } else {
        icon.innerHTML = this.uncheckedSVG
        text.classList.remove("text-emerald-600")
        text.classList.add("text-gray-400")
      }
    })
  }

  // ── Toggle password visibility ──
  toggleVisibility() {
    const input = this.inputTarget
    const isPassword = input.type === "password"
    input.type = isPassword ? "text" : "password"

    if (this.hasEyeIconTarget) {
      this.eyeIconTarget.innerHTML = isPassword ? this.eyeOffSVG : this.eyeOnSVG
    }

    input.focus()
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

  get eyeOnSVG() {
    return `<path stroke-linecap="round" stroke-linejoin="round" d="M2.036 12.322a1.012 1.012 0 010-.639C3.423 7.51 7.36 4.5 12 4.5c4.638 0 8.573 3.007 9.963 7.178.07.207.07.431 0 .639C20.577 16.49 16.64 19.5 12 19.5c-4.638 0-8.573-3.007-9.963-7.178z"/>
      <path stroke-linecap="round" stroke-linejoin="round" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>`
  }

  get eyeOffSVG() {
    return `<path stroke-linecap="round" stroke-linejoin="round" d="M3.98 8.223A10.477 10.477 0 001.934 12c1.292 4.338 5.31 7.5 10.066 7.5.993 0 1.953-.138 2.863-.395M6.228 6.228A10.45 10.45 0 0112 4.5c4.756 0 8.773 3.162 10.065 7.498a10.523 10.523 0 01-4.293 5.774M6.228 6.228L3 3m3.228 3.228l3.65 3.65m7.894 7.894L21 21m-3.228-3.228l-3.65-3.65m0 0a3 3 0 10-4.243-4.243m4.242 4.242L9.88 9.88"/>` 
  }
}
