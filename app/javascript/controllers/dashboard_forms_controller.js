import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dashboard-forms"
export default class extends Controller {
  static targets = ["availabilitiesForm", "bookingsForm"]

  availabilitiesFormToggle(event) {
    event.preventDefault()
    this.availabilitiesFormTarget.classList.toggle("d-none");
    this.bookingsFormTarget.classList.add("d-none");
  }

  bookingsFormToggle(event) {
    event.preventDefault()
    console.log("bookingsFormToggle clicked!")
    this.bookingsFormTarget.classList.toggle("d-none");
    this.availabilitiesFormTarget.classList.add("d-none");
  }
}
