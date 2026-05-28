import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["viewport", "track", "current", "thumbs", "video", "videoBadge"]

    connect() {
        this.index = 0
        this.total = this.trackTarget.children.length
        if (this.total <= 1) return

        this.touchStartX = 0
        this.viewportTarget.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
        this.viewportTarget.addEventListener("touchend", this.handleTouchEnd.bind(this), { passive: true })

        document.addEventListener("keydown", this.handleKey.bind(this))

        this.updateUI()
    }

    disconnect() {
        document.removeEventListener("keydown", this.handleKey.bind(this))
    }

    next() {
        if (this.index < this.total - 1) {
            this.index++
            this.slide()
        }
    }

    prev() {
        if (this.index > 0) {
            this.index--
            this.slide()
        }
    }

    goTo(event) {
        this.index = parseInt(event.currentTarget.dataset.index)
        this.slide()
    }

    slide() {
        const offset = this.index * -100
        this.trackTarget.style.transform = `translateX(${offset}%)`
        this.updateUI()
    }

    updateUI() {
        if (this.hasCurrentTarget) {
            this.currentTarget.textContent = this.index + 1
        }

        if (this.hasThumbsTarget) {
            this.thumbsTarget.querySelectorAll("button").forEach((btn, i) => {
                const indicator = btn.querySelector("[data-thumb-indicator]")
                if (i === this.index) {
                    btn.classList.remove("border-white/10", "hover:border-white/30")
                    btn.classList.add("border-white/40")
                    indicator?.classList.remove("opacity-0")
                    indicator?.classList.add("opacity-100")
                } else {
                    btn.classList.add("border-white/10", "hover:border-white/30")
                    btn.classList.remove("border-white/40")
                    indicator?.classList.add("opacity-0")
                    indicator?.classList.remove("opacity-100")
                }
            })
        }

        if (this.hasVideoBadgeTarget) {
            const currentSlide = this.trackTarget.children[this.index]
            const isVideo = currentSlide.querySelector("video")
            this.videoBadgeTarget.classList.toggle("hidden", !isVideo)
        }

        this.videoTargets.forEach((video) => {
            video.pause()
            video.currentTime = 0
            video.muted = true
            const overlay = video.closest("[data-slide-index]").querySelector("[data-video-overlay]")
            if (overlay) overlay.style.opacity = "1"
        })

        const currentVideo = this.trackTarget.children[this.index].querySelector("video")
        if (currentVideo) {
            currentVideo.play().catch(() => {})
            const overlay = currentVideo.closest("[data-slide-index]").querySelector("[data-video-overlay]")
            if (overlay) overlay.style.opacity = "0"
        }
    }

    handleKey(event) {
        if (event.key === "ArrowRight") this.next()
        if (event.key === "ArrowLeft") this.prev()
    }

    handleTouchStart(event) {
        this.touchStartX = event.changedTouches[0].screenX
    }

    handleTouchEnd(event) {
        const diff = this.touchStartX - event.changedTouches[0].screenX
        if (Math.abs(diff) > 50) {
            diff > 0 ? this.next() : this.prev()
        }
    }
}