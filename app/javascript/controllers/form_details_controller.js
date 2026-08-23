import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["summary", "summaryContent"]

  connect() {
    this.abortController = new AbortController();
    document.addEventListener('invalid', (e) => {
      const details = e.target.closest('details');
      if (details && !details.open) {
        details.open = true;
      }
    }, true, {
      signal: this.abortController.signal
    });
  }

  disconnect() {
    this.abortController.abort();
  }

  updateSummaryContent(event) {
    const { detail } = event.params
    window.__dbg = window.__dbg || []
    window.__dbg.push([event.target.tagName, event.target.value, detail])
    this.summaryContentTarget.textContent = event.target.value
  }
}