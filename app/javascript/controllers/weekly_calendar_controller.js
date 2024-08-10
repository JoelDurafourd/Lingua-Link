import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="weekly-calendar"
export default class extends Controller {
  static targets = ["calendarRenderSpace"]

  connect() {
    console.log("connected to weekly-calendar-controller")
  }

  change(event) {
    event.preventDefault()
    const parser = new DOMParser()
    const url = event.target.href
    fetch(url)
    .then(response => response.text())
    .then(data => {
      const weeklyCalendarData = parser.parseFromString(data, 'text/html')
      const calendar = weeklyCalendarData.querySelector(".weekly-calendar")
      this.calendarRenderSpaceTarget.replaceChildren(calendar)
      console.log(url)
     })
  }
}

/* <a data-action="click->weekly-calendar#change" href="/users/18/calendars/week?date=2024-08-03">&lt; Previous Week</a> */

// creating an html parser
    // const parser = new DOMParser()
    // const studentId = event.target.dataset.id
    // const url = `http://127.0.0.1:3000/s_classes/${this.classIdValue}/students/${studentId}`
    // // console.log(url)
    // // getting an html response and parsing it
    // fetch(url).then(response => response.text()).then(data => {
    //   const studentData = parser.parseFromString(data, 'text/html')
    //   // console.log(studentData.querySelector(".student-info"))
    //   const studentDetails = studentData.querySelector(".student-info")
    //   this.detailsViewTarget.replaceChildren(studentDetails)
    //  })
