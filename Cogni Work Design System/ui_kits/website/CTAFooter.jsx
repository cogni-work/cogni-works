// website/CTAFooter.jsx — CTA band + footer
function CTAFooter() {
  return (
    <>
      <section className="cw-cta-band" id="get-started">
        <div className="cw-section-inner cw-cta-band-inner">
          <div>
            <p className="cw-eyebrow cw-eyebrow-accent">Next steps</p>
            <h2 className="cw-section-h cw-section-h-light">Ready to work<br/><span className="cw-accent">smarter?</span></h2>
          </div>
          <div className="cw-cta-actions">
            <p className="cw-cta-note">Install the marketplace, run your first infographic in 15 minutes. Everything runs on your laptop — GDPR-compliant by design.</p>
            <div className="cw-cta-row">
              <a className="cw-btn-primary cw-btn-lg" href="#">Get started →</a>
              <a className="cw-btn-ghost-dark" href="#services">Talk to services</a>
            </div>
          </div>
        </div>
      </section>
      <footer className="cw-footer">
        <div className="cw-section-inner cw-footer-inner">
          <div className="cw-footer-brand">
            <div className="cw-brand cw-brand-light">
              <Mark size={28} tone="dark"/>
              <span>cogni<span className="hy">-</span>work<span className="tld">.ai</span></span>
            </div>
            <p className="cw-footer-motto">Firmitas · Utilitas · Venustas</p>
            <p className="cw-footer-tiny">© 2026 cogni-work.ai · AGPL-3.0</p>
          </div>
          <div className="cw-footer-col">
            <h4>Platform</h4>
            <a href="#">Plugins</a><a href="#">Workflows</a><a href="#">Architecture</a><a href="#">Changelog</a>
          </div>
          <div className="cw-footer-col">
            <h4>For teams</h4>
            <a href="#">Consulting firms</a><a href="#">Sales orgs</a><a href="#">Marketing</a><a href="#">Professional services</a>
          </div>
          <div className="cw-footer-col">
            <h4>Community</h4>
            <a href="#">GitHub</a><a href="#">Contributing</a><a href="#">Partner program</a><a href="#">Security</a>
          </div>
        </div>
      </footer>
    </>
  );
}
window.CTAFooter = CTAFooter;
