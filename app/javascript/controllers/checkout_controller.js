import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["form", "error", "otpTrigger", "addressCard"]

    connect() {
        this.selectedAddressId = null
    }

    // Guest user: validate then open OTP modal
    async placeOrderAsGuest(event) {
        event.preventDefault()

        if (!this.validateAddress()) return

        const selectedAddress = document.querySelector("input[name='address_id']:checked")

        await fetch("/store-checkout-address", {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
            },
            body: JSON.stringify({
                address_id: selectedAddress.value
            })
        })

        if (this.hasOtpTriggerTarget) {
            this.otpTriggerTarget.click()
        }
    }

    // Logged-in user: validate on form submit
    submitOrder(event) {
        if (!this.validateAddress()) {
            event.preventDefault()
        }
    }

    validateAddress() {
        const selected = document.querySelector("input[name='address_id']:checked")

        if (!selected) {
            this.showError()
            return false
        }

        this.hideError()
        return true
    }

    showError() {
        if (this.hasErrorTarget) {
            this.errorTarget.classList.remove("hidden")
        }
    }

    hideError() {
        if (this.hasErrorTarget) {
            this.errorTarget.classList.add("hidden")
        }
    }

    // Toggle address selection: click to select, click again to deselect
    toggleAddress(event) {
        const clickedRadio = event.currentTarget.querySelector("input[type='radio']")
        const addressId = clickedRadio.value

        // If clicking the already-selected address, deselect it
        if (this.selectedAddressId === addressId) {
            clickedRadio.checked = false
            this.selectedAddressId = null
            this.hideError()
            return
        }

        // Otherwise, select the new one
        this.selectedAddressId = addressId
        this.hideError()
    }

    // Called when radio changes via keyboard or direct click
    addressChanged(event) {
        const radio = event.target
        if (radio.checked) {
            this.selectedAddressId = radio.value
            this.hideError()
        }
    }
}