// website/Nav.jsx — top marketing nav
const { useState } = React;

function Nav() {
  const [open, setOpen] = useState(false);
  return (
    <header className="cw-nav">
      <div className="cw-nav-inner">
        <a className="cw-brand" href="#">
          <Mark size={28} tone="light"/>
          <span>cogni<span className="hy">-</span>work<span className="tld">.ai</span></span>
        </a>
        <nav className="cw-nav-links">
          <a href="#platform">Platform</a>
          <a href="#plugins">Plugins</a>
          <a href="#who">Who it's for</a>
          <a href="#services">Services</a>
          <a href="https://github.com/cogni-work/insight-wave" target="_blank" rel="noreferrer">Docs</a>
        </nav>
        <div className="cw-nav-cta">
          <a className="cw-nav-signin" href="#">Sign in</a>
          <a className="cw-btn-primary cw-btn-sm" href="#get-started">Get started →</a>
        </div>
      </div>
    </header>
  );
}

window.Nav = Nav;
