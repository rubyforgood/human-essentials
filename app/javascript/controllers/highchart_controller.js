import { Controller } from "@hotwired/stimulus"
import Highcharts from 'highcharts';

/*
 * HighchartController is a Stimulus controller that allows you to
 * easily create Highcharts charts in views. You must define the
 * configValue via data-highchart-config-value attribute.
 */
export default class extends Controller {
  static targets = ["chart"]
  static values = {
    config: Object,
    label: String
  }

  connect() {
    this.chart = Highcharts.chart(this.chartTarget, this.configValue);
    this.nameChart();
  }

  /*
   * Highcharts renders an <svg role="img"> with no accessible name, so a screen reader announces
   * "image" and nothing else -- WCAG 1.1.1. The name comes from data-highchart-label-value where
   * a view sets one, otherwise from the chart's own title.
   *
   * This is the cheap half of the problem. A name says what the chart is; it does not convey
   * what it shows. Every chart in this app sits beside a table of the same figures, which is the
   * text alternative that actually carries the data -- see the backlog in design.md.
   */
  nameChart() {
    const svg = this.chartTarget.querySelector("svg.highcharts-root");
    if (!svg) return;
    const title = this.configValue && this.configValue.title;
    const name = this.labelValue || (title && (typeof title === "string" ? title : title.text));
    if (name) {
      svg.setAttribute("aria-label", name);
    } else {
      // Nameless and undescribed is worse than hidden: announcing "image" tells a screen reader
      // user there is something here and nothing about it.
      svg.setAttribute("aria-hidden", "true");
      svg.setAttribute("focusable", "false");
    }
  }
}
