import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["video"]

    connect() {
        this.videoTarget.pause()
        this.videoTarget.style.opacity = '0.35'
    }

    play() {
        this.videoTarget.play()
        this.videoTarget.style.opacity = '0.6'
    }

    pause() {
        this.videoTarget.pause()
        this.videoTarget.currentTime = 0
        this.videoTarget.style.opacity = '0.35'
    }
}