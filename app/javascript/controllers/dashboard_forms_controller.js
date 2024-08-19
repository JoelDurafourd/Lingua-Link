import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="dashboard-forms"
export default class extends Controller {
  static targets = ["availabilitiesForm"]
  connect() {
    console.log("dashboard-forms-controller connected")
  }

  availabilitiesFormToggle(event) {
    event.preventDefault()
    console.log("availabilitiesFormToggle clicked!")
    this.availabilitiesFormTarget.classList.toggle("d-none");
  }
}
