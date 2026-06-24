import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "conversation", "input", "micBtn", "container"]

  connect() {
    this.synthesis = window.speechSynthesis
    this.isRecording = false
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    this.SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    
    if (!this.SpeechRecognition) {
      this.showStatus("Voice not supported. Use text input.", "bg-gray-200 text-gray-700")
      this.micBtnTarget.disabled = true
      this.micBtnTarget.classList.add("opacity-50", "cursor-not-allowed")
    }
    
    if (navigator.brave !== undefined) {
      this.showStatus("Voice may not work in Brave. Use Chrome or type below.", "bg-yellow-100 text-yellow-800")
    }
  }

  disconnect() {
    this.stopRecording()
    this.synthesis.cancel()
  }

  sendMessage(event) {
    event.preventDefault()
    const text = this.inputTarget.value.trim()
    if (!text) return
    
    this.addMessage("You", text, "bg-blue-500 text-white ml-8")
    this.inputTarget.value = ""
    this.callAI(text)
  }

  toggleMic() {
    if (!this.SpeechRecognition) return
    if (this.isRecording) {
      this.stopRecording()
    } else {
      this.startRecording()
    }
  }

  startRecording() {
    this.recognition = new this.SpeechRecognition()
    this.recognition.continuous = false
    this.recognition.interimResults = false
    this.recognition.lang = "en-IN"

    this.recognition.onstart = () => {
      this.isRecording = true
      this.micBtnTarget.classList.add("animate-pulse", "bg-red-500")
      this.micBtnTarget.classList.remove("bg-blue-500")
      this.showStatus("🎤 Listening... Speak now", "bg-red-500 text-white")
    }

    this.recognition.onresult = (event) => {
      const transcript = event.results[0][0].transcript
      this.addMessage("You", transcript, "bg-blue-500 text-white ml-8")
      this.stopRecording()
      this.callAI(transcript)
    }

    this.recognition.onerror = (event) => {
      console.error("Speech error:", event.error)
      let msg = "Voice error: " + event.error
      if (event.error === "network") {
        msg = navigator.brave !== undefined 
          ? "Brave blocks voice. Use Chrome or type below." 
          : "Network error. Use text input."
      } else if (event.error === "not-allowed") {
        msg = "Mic permission denied."
      } else if (event.error === "no-speech") {
        msg = "No speech detected. Try again."
      }
      this.showStatus(msg, "bg-gray-200 text-gray-700")
      this.stopRecording()
    }

    this.recognition.onend = () => {
      if (this.isRecording) this.stopRecording()
    }

    this.recognition.start()
  }

  stopRecording() {
    this.isRecording = false
    this.micBtnTarget.classList.remove("animate-pulse", "bg-red-500")
    this.micBtnTarget.classList.add("bg-blue-500")
    if (this.recognition) this.recognition.stop()
  }

  addMessage(speaker, text, classes) {
    const div = document.createElement("div")
    div.className = `p-3 rounded-xl text-sm leading-relaxed break-words ${classes}`
    div.innerHTML = `<span class="font-bold">${speaker}:</span> ${text}`
    this.conversationTarget.appendChild(div)
    this.conversationTarget.scrollTop = this.conversationTarget.scrollHeight
  }

  callAI(text) {
    this.showStatus("🤖 AI is thinking...", "bg-orange-400 text-white")

    fetch("/voice/message", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": this.csrfToken
      },
      body: JSON.stringify({ message: text })
    })
    .then(response => {
      if (!response.ok) throw new Error("Server error: " + response.status)
      return response.json()
    })
    .then(data => {
      if (data.error) throw new Error(data.error)
      this.addMessage("Bot", data.reply, "bg-gray-200 text-gray-900 mr-8")
      this.speak(data.reply)
    })
    .catch(error => {
      console.error("Error:", error)
      this.addMessage("Error", error.message, "bg-red-500 text-white text-center")
      this.showStatus("Error. Try again.", "bg-gray-200 text-gray-700")
    })
  }

  speak(text) {
    this.synthesis.cancel()
    const utterance = new SpeechSynthesisUtterance(text)
    utterance.lang = "en-IN"
    utterance.rate = 1.0
    utterance.pitch = 1.0

    const voices = this.synthesis.getVoices()
    const indianVoice = voices.find(v => v.lang === "en-IN")
    if (indianVoice) utterance.voice = indianVoice

    utterance.onstart = () => {
      this.showStatus("🔊 Speaking...", "bg-green-500 text-white")
    }

    utterance.onend = () => {
      this.showStatus("Ready", "bg-gray-100 text-gray-600")
    }

    this.synthesis.speak(utterance)
  }

  toggleWidget() {
    this.containerTarget.classList.toggle("hidden")
    this.containerTarget.classList.toggle("flex")
  }

  showStatus(text, classes) {
    this.statusTarget.textContent = text
    this.statusTarget.className = `px-4 py-2 rounded-xl text-sm font-medium transition-all duration-300 ${classes}`
  }
}
