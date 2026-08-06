// website/MetricsBand.jsx — dark band with hero metrics
function MetricsBand() {
  return (
    <section className="cw-metrics-band">
      <div className="cw-hero-grid" aria-hidden="true">
        {[10,22,34,48,60,72,84].map((l,i) => <span key={i} style={{left: l+'%'}}/>)}
      </div>
      <div className="cw-section-inner">
        <p className="cw-eyebrow cw-eyebrow-accent">What teams report</p>
        <h2 className="cw-section-h cw-section-h-light">Methodology depth,<br/>without the overhead.</h2>
        <div className="cw-metric-row">
          <div className="cw-metric">
            <div className="cw-metric-num">3.2<span className="u">×</span></div>
            <div className="cw-metric-lab">Faster insight discovery</div>
            <p className="cw-metric-note">From scattered search to structured, cited retrieval.</p>
          </div>
          <div className="cw-metric">
            <div className="cw-metric-num">47<span className="u">%</span></div>
            <div className="cw-metric-lab">Less coordination time</div>
            <p className="cw-metric-note">Automated workflows replace status chasing.</p>
          </div>
          <div className="cw-metric">
            <div className="cw-metric-num">5<span className="u">h</span></div>
            <div className="cw-metric-lab">Saved / consultant / week</div>
            <p className="cw-metric-note">Reclaimed for high-value analysis.</p>
          </div>
        </div>
      </div>
    </section>
  );
}
window.MetricsBand = MetricsBand;
