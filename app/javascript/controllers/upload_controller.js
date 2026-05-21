import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "placeholder", "dropzone"]

  initialize() {
    this.files = []
    this.dragIndex = null
    this.maxFiles = 5 // 🔥 change limit here
  }

  connect() {
    this.bindEvents()
  }

  bindEvents() {
    this.inputTarget.addEventListener("change", (e) => {
      this.addFiles(e.target.files)
    })

    this.dropzoneTarget.addEventListener("dragover", (e) => {
      e.preventDefault()
      this.dropzoneTarget.classList.add("border-white")
    })

    this.dropzoneTarget.addEventListener("dragleave", () => {
      this.dropzoneTarget.classList.remove("border-white")
    })

    this.dropzoneTarget.addEventListener("drop", (e) => {
      e.preventDefault()
      this.dropzoneTarget.classList.remove("border-white")
      this.addFiles(e.dataTransfer.files)
    })
  }

  open() {
    this.inputTarget.click()
  }

  // 🔥 ADD FILES (WITH LIMIT + DUPLICATE CHECK)
  addFiles(newFiles) {
    let incoming = Array.from(newFiles)

    if (!this.inputTarget.multiple) {
      this.files = [incoming[0]]
    } else {
      incoming.forEach(file => {
        if (this.files.length >= this.maxFiles) return

        const duplicate = this.files.some(f =>
            f.name === file.name && f.size === file.size
        )

        if (!duplicate) {
          this.files.push(file)
        }
      })
    }

    this.syncInput()
    this.render()
  }

  // 🔥 SYNC FILES WITH INPUT
  syncInput() {
    const dt = new DataTransfer()
    this.files.forEach(file => dt.items.add(file))
    this.inputTarget.files = dt.files
  }

  // 🔥 RENDER
  render() {
    // Remove only JS previews
    this.previewTarget
        .querySelectorAll("[data-new-upload]")
        .forEach(el => el.remove())

    if (this.files.length === 0 && this.previewTarget.dataset.hasExisting !== "true") {
      this.placeholderTarget.classList.remove("hidden")
      return
    }

    this.placeholderTarget.classList.add("hidden")

    this.files.forEach((file, index) => {
      const el = this.createPreview(file, index)

      // mark preview as JS-generated
      el.dataset.newUpload = "true"

      this.previewTarget.appendChild(el)
    })
  }

  // 🔥 PREVIEW CARD
  createPreview(file, index) {
    const wrapper = document.createElement("div")

    if (this.inputTarget.multiple) {
      wrapper.className = "relative w-[30%] h-24 bg-black overflow-hidden group cursor-move"
      wrapper.draggable = true
    } else {
      wrapper.className = "relative w-full h-full bg-black overflow-hidden group"
    }

    const url = URL.createObjectURL(file)

    if (file.type.startsWith("image")) {
      wrapper.innerHTML = `<img src="${url}" class="w-full h-full object-cover">`
    } else {
      wrapper.innerHTML = `
        <video src="${url}" class="w-full h-full object-cover"></video>
      `
    }

    // 🔥 PRIMARY LABEL
    if (index === 0 && this.inputTarget.multiple) {
      const badge = document.createElement("div")
      badge.innerText = "PRIMARY"
      badge.className = "absolute bottom-1 left-1 text-[10px] bg-white text-black px-2 py-0.5"
      wrapper.appendChild(badge)
    }

    // 🔥 REMOVE BUTTON
    const btn = document.createElement("button")
    btn.innerText = "✕"
    btn.className = "absolute top-1 right-1 bg-black/70 text-white text-xs px-2 opacity-0 group-hover:opacity-100"

    btn.addEventListener("click", (e) => {
      e.stopPropagation()
      this.remove(index)
    })

    wrapper.appendChild(btn)

    // 🔥 DRAG EVENTS (REORDER)
    wrapper.addEventListener("dragstart", () => {
      this.dragIndex = index
    })

    wrapper.addEventListener("dragover", (e) => {
      e.preventDefault()
    })

    wrapper.addEventListener("drop", () => {
      this.reorder(index)
    })

    return wrapper
  }

  // 🔥 REMOVE FILE
  remove(index) {
    this.files.splice(index, 1)
    this.syncInput()
    this.render()
  }

  // 🔥 REORDER FILES
  reorder(dropIndex) {
    if (this.dragIndex === null) return

    const moved = this.files.splice(this.dragIndex, 1)[0]
    this.files.splice(dropIndex, 0, moved)

    this.dragIndex = null

    this.syncInput()
    this.render()
  }

  // 🔥 CLEAR (used by modal reset if needed)
  clear() {
    this.files = []
    this.inputTarget.value = ""
    this.render()
  }
}