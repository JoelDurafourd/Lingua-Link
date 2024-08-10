import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    console.log("Chat controller connected")
    
    // Extract the ID from the URL path
    this.chatId = this.extractChatIdFromUrl();
    console.log("Chat ID:", this.chatId);

    this.checkOutputTarget();
    this.sub = this.createActionCableChannel();
    console.log(this.sub);
  }

  extractChatIdFromUrl() {
    const pathArray = window.location.pathname.split('/');
    return pathArray[pathArray.length - 1]; // Assuming the ID is at the end of the path
  }

  checkOutputTarget() {
    if (this.outputTarget) {
      console.log("Output target found:", this.outputTarget)
    } else {
      console.error("Output target not found. Check your HTML for data-chat-target='output'")
    }
  }

  createActionCableChannel() {
    const controller = this;  // Store reference to the controller instance

    return consumer.subscriptions.create(
      { channel: "ChatChannel", id: this.chatId },
      {
        connected() {
          console.log("Connected to ChatChannel with ID:", controller.chatId)
        },

        disconnected() {
          console.log("Disconnected from ChatChannel")
        },

        received(data) {
          console.log("Received data:", data)
          controller.displayMessage(data);  // Use controller's displayMessage method
        }
      }
    );
  }

  sendMessage(event) {
    event.preventDefault();  // Prevent the default form submission

    const messageContent = {
      to: this.chatId,  // Use the chat ID as the recipient or other use
      from: '',  // Add the correct sender
      message: this.inputTarget.value.toString()
    }

    fetch('/chat/send_message', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify(messageContent)  // Convert the messageContent object to a JSON string
    })
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        return response.json();
      })
      .then(data => {
        console.log("Message sent:", data)
        this.inputTarget.value = ""  // Clear the input field
      })
      .catch(error => {
        console.log(messageContent)
        console.error('Error:', error)
      })
  }

  displayMessage(data) {
    try {
      const messageElement = document.createElement('p')
      messageElement.textContent = `${data.from}: ${data.message}`
      this.outputTarget.appendChild(messageElement)
    } catch (error) {
      console.error("Error displaying message:", error)
      console.log("Received data:", data)
    }
  }
}
