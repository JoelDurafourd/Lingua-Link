import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

// Connects to data-controller="chat"
export default class extends Controller {
  static targets = ["input", "output"]

  connect() {
    console.log("Chat controller connected");
    this.currentUser = this.parseCurrentUserData();
    console.log("Current User:", this.currentUser);

    // Extract the ID from the URL path
    this.chatId = this.extractChatIdFromUrl();
    console.log("Chat ID:", this.chatId);

    this.checkOutputTarget();
    this.sub = this.createActionCableChannel();
    console.log(this.sub);
  }

  parseCurrentUserData() {
    // Assuming the div with data-chat-current-user is a sibling of the form
    const userElement = document.querySelector('[data-chat-current-user]');
    if (userElement) {
      const userData = userElement.dataset.chatCurrentUser;
      console.log("Raw data-chat-current-user attribute:", userData); // Log raw attribute
      try {
        const parsedData = JSON.parse(userData);
        console.log("Parsed current user data:", parsedData); // Log parsed data
        return parsedData;
      } catch (e) {
        console.error("Error parsing current user data:", e);
        return null;
      }
    } else {
      console.error("Element with data-chat-current-user not found.");
      return null;
    }
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
      {
        channel: "ChatChannel",
        id: this.chatId
      },
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
      from: this.currentUser.user_id,  // Add the correct sender
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
      // Check if the message with the given ID already exists
      if (!document.querySelector(`#message-${data.message_id}`)) {
        // Create a new <p> element
        const messageElement = document.createElement('p');

        // Create a <strong> element for the sender
        const strongElement = document.createElement('strong');
        strongElement.textContent = `${data.sender}: `;

        // Create a text node for the message contents
        const messageText = document.createTextNode(data.message);

        // Append the <strong> element and the message text to the <p> element
        messageElement.appendChild(strongElement);
        messageElement.appendChild(messageText);

        // Set the ID of the <p> element
        messageElement.id = `message-${data.message_id}`;

        // Append the <p> element to the output target
        this.outputTarget.appendChild(messageElement);
      }
    } catch (error) {
      console.error("Error displaying message:", error);
      console.log("Received data:", data);
    }
  }
}
