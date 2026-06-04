import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["field"]

    connect() {
        this.errorClass = ["border-red-500", "focus:border-red-500", "focus:ring-red-500"]
        this.baseClass = ["border-gray-300", "focus:border-indigo-500", "focus:ring-indigo-500"]
    }

    // ── Validate single field (on blur / change) ──
    validateField(event) {
        const field = event.target
        const errors = this.runChecks(field)
        this.render(field, errors)
        return errors.length === 0
    }

    // ── Validate entire form (on submit) ──
    validateAll(event) {
        let isValid = true
        let firstInvalid = null

        this.fieldTargets.forEach(field => {
            const errors = this.runChecks(field)
            this.render(field, errors)
            if (errors.length > 0) {
                isValid = false
                firstInvalid = firstInvalid || field
            }
        })

        if (!isValid) {
            event.preventDefault()
            event.stopPropagation()
            firstInvalid?.focus()
        }
    }

    // ── Core validation engine ──
    runChecks(field) {
        const errors = []
        const isCheckbox = field.type === "checkbox"

        // Checkbox: check `checked`, not `value`. Everything else: check `value`.
        const rawValue = isCheckbox ? (field.checked ? "on" : "") : (field.value || "")
        const value = rawValue.toString().trim()
        const rules = this.parseRules(field)

        // Required
        if (rules.required && value === "") {
            errors.push("This field is required")
            return errors
        }

        if (value === "") return errors

        // Length
        if (rules.minLength && value.length < rules.minLength) {
            errors.push(`Minimum ${rules.minLength} characters`)
        }
        if (rules.maxLength && value.length > rules.maxLength) {
            errors.push(`Maximum ${rules.maxLength} characters`)
        }

        // Pattern (regex)
        if (rules.pattern && !new RegExp(rules.pattern).test(value)) {
            errors.push(rules.patternMessage || "Invalid format")
        }

        // Type-specific checks
        switch (rules.validateType) {
            case "email":
                if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value)) {
                    errors.push("Invalid email address")
                }
                break

            case "india-phone":
                if (!/^(\+91[\-\s]?)?[6-9]\d{9}$/.test(value)) {
                    errors.push("Invalid Indian mobile number")
                }
                break

            case "india-pin":
                if (!/^\d{6}$/.test(value)) {
                    errors.push("Must be a 6-digit PIN code")
                }
                break

            case "india-state":
                if (!/^[A-Z]{2}$/.test(value)) {
                    errors.push("Must be a 2-letter state code")
                }
                break

            case "country-in":
                if (value !== "IN") {
                    errors.push("Only India (IN) is supported")
                }
                break

            case "numeric":
                if (!/^\d+$/.test(value)) {
                    errors.push("Must be a whole number")
                }
                break
        }

        // Numeric range
        if (rules.minNumeric !== null && parseFloat(value) <= rules.minNumeric) {
            errors.push(`Must be greater than ${rules.minNumeric}`)
        }
        if (rules.maxNumeric !== null && parseFloat(value) > rules.maxNumeric) {
            errors.push(`Must be less than or equal to ${rules.maxNumeric}`)
        }

        // Password match
        if (rules.match) {
            const matchField = document.querySelector(`[name="${rules.match}"]`)
            if (matchField && value !== matchField.value) {
                errors.push("Passwords do not match")
            }
        }

        return errors
    }

    // ── Read data attributes from the DOM ──
    parseRules(field) {
        return {
            required: field.required || field.dataset.required === "true",
            minLength: parseInt(field.dataset.minLength) || null,
            maxLength: parseInt(field.dataset.maxLength) || null,
            pattern: field.dataset.pattern || null,
            patternMessage: field.dataset.patternMessage || "Invalid format",
            validateType: field.dataset.validateType || null,
            minNumeric: field.dataset.minNumeric ? parseFloat(field.dataset.minNumeric) : null,
            maxNumeric: field.dataset.maxNumeric ? parseFloat(field.dataset.maxNumeric) : null,
            match: field.dataset.validateMatch || null
        }
    }

    // ── Render errors / success state ──
    render(field, errors) {
        const wrapper = field.closest("[data-field-wrapper]") || field.parentElement
        let errorEl = wrapper.querySelector(`[data-error-for="${field.name}"]`)

        // ── Checkbox: red text on wrapper, error below ──
        if (field.type === "checkbox") {
            if (errors.length > 0) {
                wrapper.classList.add("text-red-600")
                if (!errorEl) {
                    errorEl = document.createElement("p")
                    errorEl.className = "mt-1 text-sm text-red-600 w-full"
                    errorEl.dataset.errorFor = field.name
                    wrapper.appendChild(errorEl)
                }
                errorEl.textContent = errors[0]
            } else {
                wrapper.classList.remove("text-red-600")
                if (errorEl) errorEl.remove()
            }
            return
        }

        if (field.type === "file") {
            const dashedBox = wrapper.querySelector(".border-dashed") || wrapper.querySelector("div")
            if (errors.length > 0) {
                if (dashedBox) {
                    dashedBox.classList.remove("border-black/[0.06]")
                    dashedBox.classList.add("border-red-500")
                }
                if (!errorEl) {
                    errorEl = document.createElement("p")
                    errorEl.className = "mt-1 text-sm text-red-600"
                    errorEl.dataset.errorFor = field.name
                    wrapper.appendChild(errorEl)
                }
                errorEl.textContent = errors[0]
            } else {
                if (dashedBox) {
                    dashedBox.classList.remove("border-red-500")
                    dashedBox.classList.add("border-black/[0.06]")
                }
                if (errorEl) errorEl.remove()
            }
            return
        }


        // ── Text inputs: red border + error message ──
        field.classList.remove(...this.errorClass, ...this.baseClass)

        if (errors.length > 0) {
            field.classList.add(...this.errorClass)
            if (!errorEl) {
                errorEl = document.createElement("p")
                errorEl.className = "mt-1 text-sm text-red-600"
                errorEl.dataset.errorFor = field.name
                wrapper.appendChild(errorEl)
            }
            errorEl.textContent = errors[0]
        } else {
            field.classList.add(...this.baseClass)
            if (errorEl) errorEl.remove()
        }
    }

    // ── Clear error while typing ──
    clear(event) {
        const field = event.target
        const wrapper = field.closest("[data-field-wrapper]") || field.parentElement
        const errorEl = wrapper.querySelector(`[data-error-for="${field.name}"]`)

        // Checkbox: remove red text, no border classes
        if (field.type === "checkbox") {
            wrapper.classList.remove("text-red-600")
            if (errorEl) errorEl.remove()
            return
        }

        field.classList.remove(...this.errorClass)
        field.classList.add(...this.baseClass)
        if (errorEl) errorEl.remove()
    }

    // ── Live normalization while typing ──
    normalize(event) {
        const field = event.target
        const type = field.dataset.validateType

        switch (type) {
            case "india-state":
            case "country-in":
                field.value = field.value.toUpperCase()
                break
            case "india-phone":
                field.value = field.value.replace(/\s+/g, "")
                break
            case "india-pin":
            case "numeric":
                field.value = field.value.replace(/\D/g, "")
                break
        }
    }
}