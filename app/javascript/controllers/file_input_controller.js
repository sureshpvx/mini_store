import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "dropzone", "preview", "placeholder", "videoPreview"]

  trigger() {
    this.inputTarget.click()
  }

  // Drag & Drop
  dragOver(e) {
    e.preventDefault()
    this.dropzoneTarget.classList.add("border-white", "bg-white/5")
  }

  dragLeave(e) {
    e.preventDefault()
    this.dropzoneTarget.classList.remove("border-white", "bg-white/5")
  }

  drop(e) {
    e.preventDefault()
    this.dropzoneTarget.classList.remove("border-white", "bg-white/5")
    this.inputTarget.files = e.dataTransfer.files
    this.inputTarget.dispatchEvent(new Event("change"))
  }

  // Image preview
  preview() {
    const files = Array.from(this.inputTarget.files)
    const container = this.previewTarget
    container.innerHTML = ""
    container.classList.remove("hidden")

    files.forEach((file, index) => {
      const reader = new FileReader()
      reader.onload = (e) => {
        const div = document.createElement("div")
        div.className = "relative group"
        div.innerHTML = `
          <img src="${e.target.result}" class="border border-gray-800 w-20 h-20 object-cover">
          <button type="button" data-index="${index}" data-action="click->file-input#removePreview" class="absolute top-0 right-0 bg-red-500 text-white text-[10px] w-5 h-5 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
            ×
          </button>
        `
        container.appendChild(div)
      }
      reader.readAsDataURL(file)
    })
  }

  removePreview(e) {
    e.currentTarget.parentElement.remove()
    // Note: Files can't be removed from FileList, but new selection overrides on next submit
  }

  removeExisting(e) {
    const id = e.currentTarget.dataset.imageId
    const flag = e.currentTarget.parentElement.querySelector(".remove-flag")
    flag.disabled = false
    e.currentTarget.parentElement.style.opacity = "0.3"
    e.currentTarget.remove()
  }

  // Video preview
  previewVideo() {
    const file = this.inputTarget.files[0]
    if (!file) return

    const reader = new FileReader()
    reader.onload = (e) => {
      this.placeholderTarget.classList.add("hidden")
      this.videoPreviewTarget.classList.remove("hidden")
      this.videoPreviewTarget.querySelector("video").src = e.target.result
    }
    reader.readAsDataURL(file)
  }

  clearVideo() {
    this.inputTarget.value = ""
    this.videoPreviewTarget.classList.add("hidden")
    this.placeholderTarget.classList.remove("hidden")
    this.videoPreviewTarget.querySelector("video").src = ""
  }

  removeVideo(e) {
    const flag = document.querySelector(".remove-video-flag")
    flag.disabled = false
    document.getElementById("existing-video").style.opacity = "0.3"
    e.currentTarget.remove()
  }
}