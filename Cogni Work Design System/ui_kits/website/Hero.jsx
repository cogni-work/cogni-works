// website/Hero.jsx — dark full-bleed hero
function Hero() {
  return (
    <section className="cw-hero" id="platform">
      <div className="cw-hero-grid" aria-hidden="true">
        {[8,18,28,38,50,62,72,82,92].map((l,i) => <span key={i} style={{left: l+'%'}}/>)}
      </div>
      <div className="cw-hero-inner">
        <p className="cw-eyebrow cw-eyebrow-accent">Firmitas · Utilitas · Venustas</p>
        <h1 className="cw-hero-h1">
          Smarter <span className="cw-accent">knowledge</span><br/>work for professional teams.
        </h1>
        <p className="cw-hero-lede">
          An open-source platform of 14 Claude Code plugins for consulting, sales, and marketing —
          grounded in established methodology, cited by design, reproducible end to end.
        </p>
        <div className="cw-hero-actions">
          <a className="cw-btn-primary" href="#get-started">Get started →</a>
          <a className="cw-btn-ghost-dark" href="#plugins">See the plugins</a>
        </div>
        <dl className="cw-hero-stats">
          <div><dt>14</dt><dd>Open-source plugins</dd></div>
          <div><dt>91</dt><dd>Composable skills</dd></div>
          <div><dt>74</dt><dd>Specialist agents</dd></div>
          <div><dt>AGPL</dt><dd>3.0, always</dd></div>
        </dl>
      </div>
    </section>
  );
}
window.Hero = Hero;
