import { Controller } from "@hotwired/stimulus";
// import consumer from "channels/consumer";

// // Connects to data-controller="message"
// export default class extends Controller {
//   static targets = ["output"]

//   connect() {
//     console.log("Message controller connected")
//     this.checkOutputTarget()
//     this.sub = this.createActionCableChannel();
//     console.log(this.sub);
//   }

//   checkOutputTarget() {
//     if (this.outputTarget) {
//       console.log("Output target found:", this.outputTarget)
//     } else {
//       console.error("Output target not found. Check your HTML for data-message-target='output'")
//     }
//   }

//   createActionCableChannel() {
//     const controller = this;  // Store reference to the controller instance

//     return consumer.subscriptions.create(
//       { channel: "MessageChannel" },
//       {
//         connected() {
//           // Called when the subscription is ready for use on the server
//           this.perform("get_user_data");  // 'this' refers to the subscription object
//         },

//         disconnected() {
//           // Called when the subscription has been terminated by the server
//         },

//         received(data) {
//           // Called when there's incoming data on the websocket for this channel
//           console.log(data.email);
//           controller.displayMessage(data);  // Use controller's displayMessage method
//         }
//       }
//     );
//   }

//   displayMessage(data) {
//     try {
//       const messageElement = document.createElement('p')
//       messageElement.textContent = `${data.email}`
//       this.outputTarget.appendChild(messageElement)
//     } catch (error) {
//       console.error("Error displaying message:", error)
//       console.log("Received data:", data)
//     }
//   }
// }
