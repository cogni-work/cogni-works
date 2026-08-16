/* @ds-bundle: {"format":4,"namespace":"CogniWorkDesignSystem_f069f1","components":[{"name":"CogniWorkThemeShowcase","sourcePath":"raw/cogni-work-theme-showcase.jsx"}],"sourceHashes":{"raw/cogni-work-theme-showcase.jsx":"5dc845e440dd","slides/deck-stage.js":"522102a1c71e","ui_kits/plugin/PluginDetail.jsx":"529868ae3c9e","ui_kits/plugin/RunPanel.jsx":"e6986b015f39","ui_kits/plugin/Sidebar.jsx":"75ce96ef9e11","ui_kits/shared/Mark.jsx":"82300a496948","ui_kits/website/AudienceTabs.jsx":"0c532a666b91","ui_kits/website/CTAFooter.jsx":"1d712b8c6a24","ui_kits/website/CapabilitySection.jsx":"da4bd70e8a4a","ui_kits/website/Hero.jsx":"0cdfea9a4070","ui_kits/website/MetricsBand.jsx":"6d26a8a95260","ui_kits/website/Nav.jsx":"a5f8fa361154"},"inlinedExternals":[],"unexposedExports":[]} */

(() => {

const __ds_ns = (window.CogniWorkDesignSystem_f069f1 = window.CogniWorkDesignSystem_f069f1 || {});

const __ds_scope = {};

(__ds_ns.__errors = __ds_ns.__errors || []);

// raw/cogni-work-theme-showcase.jsx
try { (() => {
const {
  useState
} = React;
const theme = {
  primary: "#111111",
  secondary: "#333333",
  accent: "#C8E62E",
  accentMuted: "#A8C424",
  accentDark: "#8BA31E",
  bg: "#FAFAF8",
  surface: "#F2F2EE",
  surfaceDark: "#111111",
  text: "#111111",
  textLight: "#FFFFFF",
  textMuted: "#6B7280",
  border: "#E0E0DC",
  success: "#2E7D32",
  warning: "#E5A100",
  danger: "#D32F2F",
  info: "#1565C0"
};
const fontLink = document.createElement("link");
fontLink.href = "https://fonts.googleapis.com/css2?family=DM+Sans:ital,opsz,wght@0,9..40,300;0,9..40,400;0,9..40,500;0,9..40,600;0,9..40,700;1,9..40,400&family=JetBrains+Mono:wght@400;500&display=swap";
fontLink.rel = "stylesheet";
document.head.appendChild(fontLink);
const s = {
  font: "'DM Sans', 'Inter', 'Calibri', sans-serif",
  mono: "'JetBrains Mono', 'Fira Code', 'Consolas', monospace"
};

/* ─── Tiny Icon Components ─── */
const IconZap = () => /*#__PURE__*/React.createElement("svg", {
  width: "18",
  height: "18",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round",
  strokeLinejoin: "round"
}, /*#__PURE__*/React.createElement("polygon", {
  points: "13 2 3 14 12 14 11 22 21 10 12 10 13 2"
}));
const IconCheck = () => /*#__PURE__*/React.createElement("svg", {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2.5",
  strokeLinecap: "round",
  strokeLinejoin: "round"
}, /*#__PURE__*/React.createElement("polyline", {
  points: "20 6 9 17 4 12"
}));
const IconArrow = () => /*#__PURE__*/React.createElement("svg", {
  width: "16",
  height: "16",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round",
  strokeLinejoin: "round"
}, /*#__PURE__*/React.createElement("line", {
  x1: "5",
  y1: "12",
  x2: "19",
  y2: "12"
}), /*#__PURE__*/React.createElement("polyline", {
  points: "12 5 19 12 12 19"
}));
const IconStar = () => /*#__PURE__*/React.createElement("svg", {
  width: "14",
  height: "14",
  viewBox: "0 0 24 24",
  fill: "currentColor"
}, /*#__PURE__*/React.createElement("polygon", {
  points: "12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"
}));
const IconMenu = () => /*#__PURE__*/React.createElement("svg", {
  width: "20",
  height: "20",
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: "2",
  strokeLinecap: "round"
}, /*#__PURE__*/React.createElement("line", {
  x1: "3",
  y1: "6",
  x2: "21",
  y2: "6"
}), /*#__PURE__*/React.createElement("line", {
  x1: "3",
  y1: "12",
  x2: "15",
  y2: "12"
}), /*#__PURE__*/React.createElement("line", {
  x1: "3",
  y1: "18",
  x2: "18",
  y2: "18"
}));

/* ─── Section Wrapper ─── */
const Section = ({
  title,
  dark,
  children,
  style
}) => /*#__PURE__*/React.createElement("div", {
  style: {
    background: dark ? theme.surfaceDark : theme.bg,
    padding: "48px 40px",
    ...style
  }
}, /*#__PURE__*/React.createElement("div", {
  style: {
    fontSize: 11,
    fontWeight: 600,
    letterSpacing: "0.12em",
    textTransform: "uppercase",
    color: dark ? theme.accent : theme.textMuted,
    marginBottom: 8,
    fontFamily: s.mono
  }
}, title), children);

/* ─── Main Component ─── */
function CogniWorkThemeShowcase() {
  const [activeTab, setActiveTab] = useState(0);
  const [toggle, setToggle] = useState(true);
  const [sliderVal, setSliderVal] = useState(65);
  const [selectedCard, setSelectedCard] = useState(1);
  const tabs = ["Overview", "Components", "Patterns"];
  return /*#__PURE__*/React.createElement("div", {
    style: {
      fontFamily: s.font,
      color: theme.text,
      background: theme.bg,
      minHeight: "100vh",
      maxWidth: 960,
      margin: "0 auto"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: theme.surfaceDark,
      padding: "56px 40px 48px",
      position: "relative",
      overflow: "hidden"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      opacity: 0.04
    }
  }, Array.from({
    length: 12
  }).map((_, i) => /*#__PURE__*/React.createElement("div", {
    key: i,
    style: {
      position: "absolute",
      left: `${(i + 1) * 80}px`,
      top: 0,
      bottom: 0,
      width: 1,
      background: theme.accent
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "relative",
      zIndex: 1
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 12,
      marginBottom: 32
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 36,
      height: 36,
      borderRadius: 8,
      background: theme.accent,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: theme.primary
    }
  }, /*#__PURE__*/React.createElement(IconZap, null)), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.textLight,
      fontWeight: 700,
      fontSize: 18,
      letterSpacing: "-0.02em"
    }
  }, "cogni", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.accent
    }
  }, "-"), "work")), /*#__PURE__*/React.createElement("h1", {
    style: {
      color: theme.textLight,
      fontSize: 42,
      fontWeight: 700,
      lineHeight: 1.1,
      letterSpacing: "-0.03em",
      margin: 0,
      maxWidth: 560
    }
  }, "Theme ", /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.accent
    }
  }, "Showcase")), /*#__PURE__*/React.createElement("p", {
    style: {
      color: theme.textMuted,
      fontSize: 16,
      lineHeight: 1.6,
      marginTop: 16,
      maxWidth: 480
    }
  }, "Firmitas \xB7 Utilitas \xB7 Venustas \u2014 Vitruvius' Triade als Design-System. Elektrisches Chartreuse auf tiefem Schwarz."))), /*#__PURE__*/React.createElement(Section, {
    title: "Farbpalette"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(auto-fill, minmax(130px, 1fr))",
      gap: 12,
      marginTop: 16
    }
  }, [{
    name: "Primary",
    hex: theme.primary,
    light: true
  }, {
    name: "Secondary",
    hex: theme.secondary,
    light: true
  }, {
    name: "Accent",
    hex: theme.accent
  }, {
    name: "Accent Muted",
    hex: theme.accentMuted
  }, {
    name: "Accent Dark",
    hex: theme.accentDark
  }, {
    name: "Background",
    hex: theme.bg
  }, {
    name: "Surface",
    hex: theme.surface
  }, {
    name: "Text Muted",
    hex: theme.textMuted,
    light: true
  }, {
    name: "Border",
    hex: theme.border
  }, {
    name: "Success",
    hex: theme.success,
    light: true
  }, {
    name: "Warning",
    hex: theme.warning
  }, {
    name: "Danger",
    hex: theme.danger,
    light: true
  }].map(c => /*#__PURE__*/React.createElement("div", {
    key: c.name,
    style: {
      borderRadius: 10,
      overflow: "hidden",
      border: `1px solid ${theme.border}`
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: c.hex,
      height: 56
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "8px 10px",
      background: "#fff"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: theme.text
    }
  }, c.name), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontFamily: s.mono,
      color: theme.textMuted,
      marginTop: 2
    }
  }, c.hex)))))), /*#__PURE__*/React.createElement(Section, {
    title: "Typografie",
    dark: true
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 20
    }
  }, [{
    label: "H1",
    size: 42,
    weight: 700,
    ls: "-0.03em"
  }, {
    label: "H2",
    size: 32,
    weight: 700,
    ls: "-0.02em"
  }, {
    label: "H3",
    size: 24,
    weight: 600,
    ls: "-0.01em"
  }, {
    label: "H4",
    size: 18,
    weight: 600,
    ls: "0"
  }].map(t => /*#__PURE__*/React.createElement("div", {
    key: t.label,
    style: {
      display: "flex",
      alignItems: "baseline",
      gap: 20,
      marginBottom: 16
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 11,
      color: theme.accent,
      width: 28,
      flexShrink: 0
    }
  }, t.label), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: t.size,
      fontWeight: t.weight,
      letterSpacing: t.ls,
      color: theme.textLight,
      lineHeight: 1.2
    }
  }, "DM Sans ", t.weight === 700 ? "Bold" : "Semibold"))), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: `1px solid rgba(200,230,46,0.15)`,
      marginTop: 8,
      paddingTop: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "baseline",
      gap: 20,
      marginBottom: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 11,
      color: theme.accent,
      width: 28,
      flexShrink: 0
    }
  }, "P"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 15,
      color: "rgba(255,255,255,0.8)",
      lineHeight: 1.65,
      maxWidth: 520
    }
  }, "Body-Text in DM Sans Regular \u2014 klar, lesbar, mit gro\xDFz\xFCgigem Zeilenabstand. Chartreuse akzentuiert nur das Wesentliche.")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "baseline",
      gap: 20
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 11,
      color: theme.accent,
      width: 28,
      flexShrink: 0
    }
  }, "</>"), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 13,
      color: theme.accent,
      opacity: 0.8
    }
  }, "JetBrains Mono \u2014 Code & Monospace"))))), /*#__PURE__*/React.createElement(Section, {
    title: "Buttons & Interaktionen"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      flexWrap: "wrap",
      gap: 12,
      marginTop: 16,
      alignItems: "center"
    }
  }, /*#__PURE__*/React.createElement("button", {
    style: {
      background: theme.accent,
      color: theme.primary,
      border: "none",
      borderRadius: 8,
      padding: "12px 24px",
      fontSize: 14,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer",
      display: "flex",
      alignItems: "center",
      gap: 8,
      transition: "background 0.2s"
    },
    onMouseEnter: e => e.target.style.background = theme.accentMuted,
    onMouseLeave: e => e.target.style.background = theme.accent
  }, "Prim\xE4r-CTA ", /*#__PURE__*/React.createElement(IconArrow, null)), /*#__PURE__*/React.createElement("button", {
    style: {
      background: "transparent",
      color: theme.text,
      border: `1.5px solid ${theme.primary}`,
      borderRadius: 8,
      padding: "11px 24px",
      fontSize: 14,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer"
    }
  }, "Sekund\xE4r"), /*#__PURE__*/React.createElement("button", {
    style: {
      background: "transparent",
      color: theme.textMuted,
      border: `1.5px solid ${theme.border}`,
      borderRadius: 8,
      padding: "11px 24px",
      fontSize: 14,
      fontWeight: 500,
      fontFamily: s.font,
      cursor: "pointer"
    }
  }, "Ghost"), /*#__PURE__*/React.createElement("button", {
    style: {
      background: theme.primary,
      color: theme.textLight,
      border: "none",
      borderRadius: 8,
      padding: "12px 24px",
      fontSize: 14,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer"
    }
  }, "Dark"), /*#__PURE__*/React.createElement("button", {
    style: {
      background: theme.accent,
      color: theme.primary,
      border: "none",
      borderRadius: 6,
      padding: "7px 14px",
      fontSize: 12,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer"
    }
  }, "Klein")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 32,
      marginTop: 28,
      alignItems: "center",
      flexWrap: "wrap"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: theme.textMuted
    }
  }, "Toggle"), /*#__PURE__*/React.createElement("div", {
    onClick: () => setToggle(!toggle),
    style: {
      width: 44,
      height: 24,
      borderRadius: 12,
      background: toggle ? theme.accent : theme.border,
      cursor: "pointer",
      position: "relative",
      transition: "background 0.25s"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 18,
      height: 18,
      borderRadius: 9,
      background: "#fff",
      position: "absolute",
      top: 3,
      left: toggle ? 23 : 3,
      transition: "left 0.25s",
      boxShadow: "0 1px 3px rgba(0,0,0,0.2)"
    }
  }))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10,
      flex: 1,
      minWidth: 200
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      color: theme.textMuted
    }
  }, "Slider"), /*#__PURE__*/React.createElement("div", {
    style: {
      flex: 1,
      position: "relative",
      height: 6,
      borderRadius: 3,
      background: theme.border
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${sliderVal}%`,
      height: "100%",
      borderRadius: 3,
      background: theme.accent,
      transition: "width 0.1s"
    }
  }), /*#__PURE__*/React.createElement("input", {
    type: "range",
    min: 0,
    max: 100,
    value: sliderVal,
    onChange: e => setSliderVal(+e.target.value),
    style: {
      position: "absolute",
      top: -8,
      left: 0,
      width: "100%",
      height: 20,
      opacity: 0,
      cursor: "pointer"
    }
  }), /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      left: `calc(${sliderVal}% - 8px)`,
      top: -5,
      width: 16,
      height: 16,
      borderRadius: 8,
      background: theme.accent,
      border: "2px solid #fff",
      boxShadow: "0 1px 4px rgba(0,0,0,0.15)",
      pointerEvents: "none"
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 12,
      color: theme.accent,
      width: 32,
      textAlign: "right"
    }
  }, sliderVal, "%")))), /*#__PURE__*/React.createElement(Section, {
    title: "Navigation & Tabs",
    style: {
      background: theme.surface
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      background: theme.primary,
      borderRadius: 10,
      padding: "14px 20px",
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      marginTop: 16
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 10
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 26,
      height: 26,
      borderRadius: 6,
      background: theme.accent,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: theme.primary
    }
  }, /*#__PURE__*/React.createElement(IconZap, null)), /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.textLight,
      fontWeight: 600,
      fontSize: 14
    }
  }, "cogni-work")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 24,
      alignItems: "center"
    }
  }, ["Projekte", "Kunden", "Berichte"].map((item, i) => /*#__PURE__*/React.createElement("span", {
    key: item,
    style: {
      color: i === 0 ? theme.accent : "rgba(255,255,255,0.55)",
      fontSize: 13,
      fontWeight: i === 0 ? 600 : 400,
      cursor: "pointer"
    }
  }, item)), /*#__PURE__*/React.createElement("div", {
    style: {
      color: "rgba(255,255,255,0.6)",
      cursor: "pointer"
    }
  }, /*#__PURE__*/React.createElement(IconMenu, null)))), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 0,
      marginTop: 20,
      borderBottom: `2px solid ${theme.border}`
    }
  }, tabs.map((tab, i) => /*#__PURE__*/React.createElement("button", {
    key: tab,
    onClick: () => setActiveTab(i),
    style: {
      background: "none",
      border: "none",
      borderBottom: activeTab === i ? `2px solid ${theme.accent}` : "2px solid transparent",
      marginBottom: -2,
      padding: "10px 20px",
      fontSize: 13,
      fontWeight: activeTab === i ? 600 : 400,
      color: activeTab === i ? theme.text : theme.textMuted,
      cursor: "pointer",
      fontFamily: s.font,
      transition: "all 0.2s"
    }
  }, tab))), /*#__PURE__*/React.createElement("div", {
    style: {
      padding: "16px 0",
      fontSize: 14,
      color: theme.textMuted,
      lineHeight: 1.6
    }
  }, "Aktiver Tab: ", /*#__PURE__*/React.createElement("strong", {
    style: {
      color: theme.text
    }
  }, tabs[activeTab]), " \u2014 Inhalte werden hier angezeigt.")), /*#__PURE__*/React.createElement(Section, {
    title: "Karten & Panels"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(auto-fit, minmax(240px, 1fr))",
      gap: 16,
      marginTop: 16
    }
  }, [{
    title: "Firmitas",
    desc: "Dunkle Strukturanker geben Stabilität und Fundament.",
    metric: "98%",
    sub: "Solidität"
  }, {
    title: "Utilitas",
    desc: "Maximaler Kontrast für klare Lesbarkeit und Funktion.",
    metric: "4.5:1",
    sub: "Kontrast"
  }, {
    title: "Venustas",
    desc: "Chartreuse als Signatur — mutig, einprägsam, unverwechselbar.",
    metric: "#C8E62E",
    sub: "Accent"
  }].map((card, i) => /*#__PURE__*/React.createElement("div", {
    key: card.title,
    onClick: () => setSelectedCard(i),
    style: {
      background: "#fff",
      border: selectedCard === i ? `2px solid ${theme.accent}` : `1px solid ${theme.border}`,
      borderRadius: 12,
      padding: 24,
      cursor: "pointer",
      transition: "all 0.2s",
      boxShadow: selectedCard === i ? `0 0 0 3px rgba(200,230,46,0.15)` : "none"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      justifyContent: "space-between",
      alignItems: "flex-start"
    }
  }, /*#__PURE__*/React.createElement("h3", {
    style: {
      margin: 0,
      fontSize: 17,
      fontWeight: 700,
      letterSpacing: "-0.01em"
    }
  }, card.title), selectedCard === i && /*#__PURE__*/React.createElement("span", {
    style: {
      color: theme.accent
    }
  }, /*#__PURE__*/React.createElement(IconCheck, null))), /*#__PURE__*/React.createElement("p", {
    style: {
      fontSize: 13,
      color: theme.textMuted,
      lineHeight: 1.55,
      margin: "10px 0 16px"
    }
  }, card.desc), /*#__PURE__*/React.createElement("div", {
    style: {
      borderTop: `1px solid ${theme.border}`,
      paddingTop: 12,
      display: "flex",
      justifyContent: "space-between",
      alignItems: "baseline"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 18,
      fontWeight: 700,
      color: theme.accent
    }
  }, card.metric), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 11,
      color: theme.textMuted,
      textTransform: "uppercase",
      letterSpacing: "0.06em"
    }
  }, card.sub)))))), /*#__PURE__*/React.createElement(Section, {
    title: "Status & Daten",
    dark: true
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 10,
      marginTop: 16,
      flexWrap: "wrap"
    }
  }, [{
    label: "Aktiv",
    bg: "rgba(46,125,50,0.15)",
    color: theme.success
  }, {
    label: "Warnung",
    bg: "rgba(229,161,0,0.15)",
    color: theme.warning
  }, {
    label: "Fehler",
    bg: "rgba(211,47,47,0.15)",
    color: theme.danger
  }, {
    label: "Info",
    bg: "rgba(21,101,192,0.15)",
    color: theme.info
  }, {
    label: "Neu",
    bg: "rgba(200,230,46,0.12)",
    color: theme.accent
  }].map(b => /*#__PURE__*/React.createElement("span", {
    key: b.label,
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      background: b.bg,
      color: b.color,
      fontSize: 12,
      fontWeight: 600,
      padding: "5px 12px",
      borderRadius: 6
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: 3,
      background: b.color
    }
  }), b.label))), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 24,
      borderRadius: 10,
      overflow: "hidden",
      border: "1px solid rgba(255,255,255,0.08)"
    }
  }, /*#__PURE__*/React.createElement("table", {
    style: {
      width: "100%",
      borderCollapse: "collapse",
      fontSize: 13
    }
  }, /*#__PURE__*/React.createElement("thead", null, /*#__PURE__*/React.createElement("tr", {
    style: {
      background: "rgba(255,255,255,0.04)"
    }
  }, ["Projekt", "Status", "Score", "Trend"].map(h => /*#__PURE__*/React.createElement("th", {
    key: h,
    style: {
      textAlign: "left",
      padding: "10px 16px",
      fontSize: 11,
      fontWeight: 600,
      textTransform: "uppercase",
      letterSpacing: "0.08em",
      color: theme.accent,
      fontFamily: s.mono,
      borderBottom: "1px solid rgba(255,255,255,0.06)"
    }
  }, h)))), /*#__PURE__*/React.createElement("tbody", null, [{
    name: "cogni-workspace",
    status: "Aktiv",
    statusColor: theme.success,
    score: 94,
    trend: "+12%"
  }, {
    name: "cogni-portfolio",
    status: "In Arbeit",
    statusColor: theme.warning,
    score: 78,
    trend: "+5%"
  }, {
    name: "trend-scout",
    status: "Planung",
    statusColor: theme.info,
    score: 62,
    trend: "Neu"
  }].map(row => /*#__PURE__*/React.createElement("tr", {
    key: row.name,
    style: {
      borderBottom: "1px solid rgba(255,255,255,0.04)"
    }
  }, /*#__PURE__*/React.createElement("td", {
    style: {
      padding: "12px 16px",
      color: theme.textLight,
      fontWeight: 500
    }
  }, row.name), /*#__PURE__*/React.createElement("td", {
    style: {
      padding: "12px 16px"
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      display: "inline-flex",
      alignItems: "center",
      gap: 6,
      color: row.statusColor,
      fontSize: 12
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      width: 6,
      height: 6,
      borderRadius: 3,
      background: row.statusColor
    }
  }), row.status)), /*#__PURE__*/React.createElement("td", {
    style: {
      padding: "12px 16px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 60,
      height: 5,
      borderRadius: 3,
      background: "rgba(255,255,255,0.08)"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: `${row.score}%`,
      height: "100%",
      borderRadius: 3,
      background: theme.accent
    }
  })), /*#__PURE__*/React.createElement("span", {
    style: {
      fontFamily: s.mono,
      fontSize: 12,
      color: theme.accent
    }
  }, row.score))), /*#__PURE__*/React.createElement("td", {
    style: {
      padding: "12px 16px",
      fontFamily: s.mono,
      fontSize: 12,
      color: row.trend.startsWith("+") ? theme.accent : theme.textMuted
    }
  }, row.trend))))))), /*#__PURE__*/React.createElement(Section, {
    title: "KPI Dashboard"
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(auto-fit, minmax(180px, 1fr))",
      gap: 16,
      marginTop: 16
    }
  }, [{
    label: "Revenue",
    value: "€128K",
    change: "+18%",
    up: true
  }, {
    label: "Kunden",
    value: "47",
    change: "+6",
    up: true
  }, {
    label: "NPS Score",
    value: "72",
    change: "-3",
    up: false
  }, {
    label: "Projekte",
    value: "12",
    change: "3 aktiv",
    up: null
  }].map(kpi => /*#__PURE__*/React.createElement("div", {
    key: kpi.label,
    style: {
      background: "#fff",
      border: `1px solid ${theme.border}`,
      borderRadius: 10,
      padding: "20px 20px 16px"
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 11,
      fontWeight: 500,
      color: theme.textMuted,
      textTransform: "uppercase",
      letterSpacing: "0.06em"
    }
  }, kpi.label), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 28,
      fontWeight: 700,
      color: theme.text,
      letterSpacing: "-0.02em",
      marginTop: 6
    }
  }, kpi.value), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      fontFamily: s.mono,
      marginTop: 6,
      color: kpi.up === true ? theme.success : kpi.up === false ? theme.danger : theme.textMuted
    }
  }, kpi.change))))), /*#__PURE__*/React.createElement(Section, {
    title: "Formulare",
    style: {
      background: theme.surface
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: 16,
      marginTop: 16,
      maxWidth: 560
    }
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("label", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: theme.text,
      display: "block",
      marginBottom: 6
    }
  }, "Name"), /*#__PURE__*/React.createElement("input", {
    placeholder: "Stephan de Haas",
    style: {
      width: "100%",
      padding: "10px 14px",
      borderRadius: 8,
      border: `1.5px solid ${theme.border}`,
      fontSize: 14,
      fontFamily: s.font,
      background: "#fff",
      outline: "none",
      boxSizing: "border-box"
    },
    onFocus: e => e.target.style.borderColor = theme.accent,
    onBlur: e => e.target.style.borderColor = theme.border
  })), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("label", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: theme.text,
      display: "block",
      marginBottom: 6
    }
  }, "E-Mail"), /*#__PURE__*/React.createElement("input", {
    placeholder: "stephan@cogni-work.ai",
    style: {
      width: "100%",
      padding: "10px 14px",
      borderRadius: 8,
      border: `1.5px solid ${theme.border}`,
      fontSize: 14,
      fontFamily: s.font,
      background: "#fff",
      outline: "none",
      boxSizing: "border-box"
    },
    onFocus: e => e.target.style.borderColor = theme.accent,
    onBlur: e => e.target.style.borderColor = theme.border
  })), /*#__PURE__*/React.createElement("div", {
    style: {
      gridColumn: "1 / -1"
    }
  }, /*#__PURE__*/React.createElement("label", {
    style: {
      fontSize: 12,
      fontWeight: 600,
      color: theme.text,
      display: "block",
      marginBottom: 6
    }
  }, "Nachricht"), /*#__PURE__*/React.createElement("textarea", {
    placeholder: "Ihre Anfrage...",
    rows: 3,
    style: {
      width: "100%",
      padding: "10px 14px",
      borderRadius: 8,
      border: `1.5px solid ${theme.border}`,
      fontSize: 14,
      fontFamily: s.font,
      background: "#fff",
      outline: "none",
      resize: "vertical",
      boxSizing: "border-box"
    },
    onFocus: e => e.target.style.borderColor = theme.accent,
    onBlur: e => e.target.style.borderColor = theme.border
  }))), /*#__PURE__*/React.createElement("button", {
    style: {
      background: theme.accent,
      color: theme.primary,
      border: "none",
      borderRadius: 8,
      padding: "12px 28px",
      fontSize: 14,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer",
      marginTop: 16,
      display: "flex",
      alignItems: "center",
      gap: 8
    }
  }, "Absenden ", /*#__PURE__*/React.createElement(IconArrow, null))), /*#__PURE__*/React.createElement(Section, {
    title: "Pricing-Beispiel",
    dark: true
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "grid",
      gridTemplateColumns: "repeat(auto-fit, minmax(220px, 1fr))",
      gap: 16,
      marginTop: 20
    }
  }, [{
    tier: "Starter",
    price: "€490",
    period: "/Monat",
    features: ["5 Projekte", "E-Mail Support", "Basis-Reports"],
    highlight: false
  }, {
    tier: "Professional",
    price: "€990",
    period: "/Monat",
    features: ["Unbegrenzt", "Priority Support", "Custom Reports", "API Zugang"],
    highlight: true
  }, {
    tier: "Enterprise",
    price: "Individuell",
    period: "",
    features: ["Dedicated Team", "24/7 Support", "On-Premise", "SLA"],
    highlight: false
  }].map(plan => /*#__PURE__*/React.createElement("div", {
    key: plan.tier,
    style: {
      background: plan.highlight ? theme.accent : "rgba(255,255,255,0.04)",
      border: plan.highlight ? "none" : "1px solid rgba(255,255,255,0.08)",
      borderRadius: 12,
      padding: 28,
      color: plan.highlight ? theme.primary : theme.textLight,
      position: "relative"
    }
  }, plan.highlight && /*#__PURE__*/React.createElement("div", {
    style: {
      position: "absolute",
      top: -1,
      right: 16,
      background: theme.primary,
      color: theme.accent,
      fontSize: 10,
      fontWeight: 700,
      padding: "4px 10px",
      borderRadius: "0 0 6px 6px",
      textTransform: "uppercase",
      letterSpacing: "0.08em"
    }
  }, "Empfohlen"), /*#__PURE__*/React.createElement("div", {
    style: {
      fontSize: 13,
      fontWeight: 600,
      opacity: plan.highlight ? 0.7 : 0.5,
      textTransform: "uppercase",
      letterSpacing: "0.06em"
    }
  }, plan.tier), /*#__PURE__*/React.createElement("div", {
    style: {
      marginTop: 12,
      marginBottom: 20
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 32,
      fontWeight: 700,
      letterSpacing: "-0.02em"
    }
  }, plan.price), /*#__PURE__*/React.createElement("span", {
    style: {
      fontSize: 13,
      opacity: 0.6
    }
  }, plan.period)), plan.features.map(f => /*#__PURE__*/React.createElement("div", {
    key: f,
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8,
      marginBottom: 10,
      fontSize: 13
    }
  }, /*#__PURE__*/React.createElement("span", {
    style: {
      color: plan.highlight ? theme.primary : theme.accent
    }
  }, /*#__PURE__*/React.createElement(IconCheck, null)), /*#__PURE__*/React.createElement("span", {
    style: {
      opacity: 0.85
    }
  }, f))), /*#__PURE__*/React.createElement("button", {
    style: {
      width: "100%",
      marginTop: 12,
      padding: "11px 0",
      borderRadius: 8,
      border: plan.highlight ? `1.5px solid ${theme.primary}` : `1.5px solid rgba(200,230,46,0.4)`,
      background: plan.highlight ? theme.primary : "transparent",
      color: plan.highlight ? theme.accent : theme.accent,
      fontSize: 13,
      fontWeight: 600,
      fontFamily: s.font,
      cursor: "pointer"
    }
  }, "Ausw\xE4hlen"))))), /*#__PURE__*/React.createElement("div", {
    style: {
      background: theme.surfaceDark,
      padding: "32px 40px",
      display: "flex",
      justifyContent: "space-between",
      alignItems: "center",
      flexWrap: "wrap",
      gap: 12
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      alignItems: "center",
      gap: 8
    }
  }, /*#__PURE__*/React.createElement("div", {
    style: {
      width: 22,
      height: 22,
      borderRadius: 5,
      background: theme.accent,
      display: "flex",
      alignItems: "center",
      justifyContent: "center",
      color: theme.primary
    }
  }, /*#__PURE__*/React.createElement(IconZap, null)), /*#__PURE__*/React.createElement("span", {
    style: {
      color: "rgba(255,255,255,0.5)",
      fontSize: 13
    }
  }, "cogni-work Theme \xB7 Firmitas \xB7 Utilitas \xB7 Venustas")), /*#__PURE__*/React.createElement("div", {
    style: {
      display: "flex",
      gap: 4,
      alignItems: "center"
    }
  }, [1, 2, 3, 4, 5].map(n => /*#__PURE__*/React.createElement("span", {
    key: n,
    style: {
      color: theme.accent,
      opacity: n <= 4 ? 1 : 0.3
    }
  }, /*#__PURE__*/React.createElement(IconStar, null))))));
}
Object.assign(__ds_scope, { CogniWorkThemeShowcase, __ds_default_raw_cogni_work_theme_showcase_1d52h60: CogniWorkThemeShowcase });
})(); } catch (e) { __ds_ns.__errors.push({ path: "raw/cogni-work-theme-showcase.jsx", error: String((e && e.message) || e) }); }

// slides/deck-stage.js
try { (() => {
/**
 * <deck-stage> — reusable web component for HTML decks.
 *
 * Handles:
 *  (a) speaker notes — reads <script type="application/json" id="speaker-notes">
 *      and posts {slideIndexChanged: N} to the parent window on nav.
 *  (b) keyboard navigation — ←/→, PgUp/PgDn, Space, Home/End, number keys.
 *  (c) press R to reset to slide 0 (with a tasteful keyboard hint).
 *  (d) bottom-center overlay showing slide count + hints, fades out on idle.
 *  (e) auto-scaling — inner canvas is a fixed design size (default 1920×1080)
 *      scaled with `transform: scale()` to fit the viewport, letterboxed.
 *      Set the `noscale` attribute to render at authored size (1:1) — the
 *      PPTX exporter sets this so its DOM capture sees unscaled geometry.
 *  (f) print — `@media print` lays every slide out as its own page at the
 *      design size, so the browser's Print → Save as PDF produces a clean
 *      one-page-per-slide PDF with no extra setup.
 *
 * Slides are HIDDEN, not unmounted. Non-active slides stay in the DOM with
 * `visibility: hidden` + `opacity: 0`, so their state (videos, iframes,
 * form inputs, React trees) is preserved across navigation.
 *
 * Lifecycle event — the component dispatches a `slidechange` CustomEvent on
 * itself whenever the active slide changes (including the initial mount).
 * The event bubbles and composes out of shadow DOM, so you can listen on
 * the <deck-stage> element or on document:
 *
 *   document.querySelector('deck-stage').addEventListener('slidechange', (e) => {
 *     e.detail.index         // new 0-based index
 *     e.detail.previousIndex // previous index, or -1 on init
 *     e.detail.total         // total slide count
 *     e.detail.slide         // the new active slide element
 *     e.detail.previousSlide // the prior slide element, or null on init
 *     e.detail.reason        // 'init' | 'keyboard' | 'click' | 'tap' | 'api'
 *   });
 *
 * Persistence: current slide index is saved to localStorage keyed by the
 * document path, so refresh returns you to the same place.
 *
 * Usage:
 *   <deck-stage width="1920" height="1080">
 *     <section data-label="Title">...</section>
 *     <section data-label="Agenda">...</section>
 *   </deck-stage>
 *
 * Slides are the direct element children of <deck-stage>. Each slide is
 * automatically tagged with:
 *   - data-screen-label="NN Label"   (1-indexed, for comment flow)
 *   - data-om-validate="no_overflowing_text,no_overlapping_text,slide_sized_text"
 */

(() => {
  const DESIGN_W_DEFAULT = 1920;
  const DESIGN_H_DEFAULT = 1080;
  const STORAGE_PREFIX = 'deck-stage:slide:';
  const OVERLAY_HIDE_MS = 1800;
  const VALIDATE_ATTR = 'no_overflowing_text,no_overlapping_text,slide_sized_text';
  const pad2 = n => String(n).padStart(2, '0');
  const stylesheet = `
    :host {
      position: fixed;
      inset: 0;
      display: block;
      background: #000;
      color: #fff;
      font-family: -apple-system, BlinkMacSystemFont, "Helvetica Neue", Helvetica, Arial, sans-serif;
      overflow: hidden;
    }

    .stage {
      position: absolute;
      inset: 0;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .canvas {
      position: relative;
      transform-origin: center center;
      flex-shrink: 0;
      background: #fff;
      will-change: transform;
    }

    /* Slides live in light DOM (via <slot>) so authored CSS still applies.
       We absolutely position each slotted child to stack them. */
    ::slotted(*) {
      position: absolute !important;
      inset: 0 !important;
      width: 100% !important;
      height: 100% !important;
      box-sizing: border-box !important;
      overflow: hidden;
      opacity: 0;
      pointer-events: none;
      visibility: hidden;
    }
    ::slotted([data-deck-active]) {
      opacity: 1;
      pointer-events: auto;
      visibility: visible;
    }

    /* Tap zones for mobile — back/forward thirds like Stories.
       Transparent, no visible UI, don't block the overlay. */
    .tapzones {
      position: fixed;
      inset: 0;
      display: flex;
      z-index: 2147482000;
      pointer-events: none;
    }
    .tapzone {
      flex: 1;
      pointer-events: auto;
      -webkit-tap-highlight-color: transparent;
    }
    /* Only activate tap zones on coarse pointers (touch devices). */
    @media (hover: hover) and (pointer: fine) {
      .tapzones { display: none; }
    }

    .overlay {
      position: fixed;
      left: 50%;
      bottom: 22px;
      transform: translate(-50%, 6px) scale(0.92);
      filter: blur(6px);
      display: flex;
      align-items: center;
      gap: 4px;
      padding: 4px;
      background: #000;
      color: #fff;
      border-radius: 999px;
      font-size: 12px;
      font-feature-settings: "tnum" 1;
      letter-spacing: 0.01em;
      opacity: 0;
      pointer-events: none;
      transition: opacity 260ms ease, transform 260ms cubic-bezier(.2,.8,.2,1), filter 260ms ease;
      transform-origin: center bottom;
      z-index: 2147483000;
      user-select: none;
    }
    .overlay[data-visible] {
      opacity: 1;
      pointer-events: auto;
      transform: translate(-50%, 0) scale(1);
      filter: blur(0);
    }

    .btn {
      appearance: none;
      -webkit-appearance: none;
      background: transparent;
      border: 0;
      margin: 0;
      padding: 0;
      color: inherit;
      font: inherit;
      cursor: default;
      display: inline-flex;
      align-items: center;
      justify-content: center;
      height: 28px;
      min-width: 28px;
      border-radius: 999px;
      color: rgba(255,255,255,0.72);
      transition: background 140ms ease, color 140ms ease;
      -webkit-tap-highlight-color: transparent;
    }
    .btn:hover { background: rgba(255,255,255,0.12); color: #fff; }
    .btn:active { background: rgba(255,255,255,0.18); }
    .btn:focus { outline: none; }
    .btn:focus-visible { outline: none; }
    .btn::-moz-focus-inner { border: 0; }
    .btn svg { width: 14px; height: 14px; display: block; }
    .btn.reset {
      font-size: 11px;
      font-weight: 500;
      letter-spacing: 0.02em;
      padding: 0 10px 0 12px;
      gap: 6px;
      color: rgba(255,255,255,0.72);
    }
    .btn.reset .kbd {
      display: inline-flex;
      align-items: center;
      justify-content: center;
      min-width: 16px;
      height: 16px;
      padding: 0 4px;
      font-family: ui-monospace, "SF Mono", Menlo, Consolas, monospace;
      font-size: 10px;
      line-height: 1;
      color: rgba(255,255,255,0.88);
      background: rgba(255,255,255,0.12);
      border-radius: 4px;
    }

    .count {
      font-variant-numeric: tabular-nums;
      color: #fff;
      font-weight: 500;
      padding: 0 8px;
      min-width: 42px;
      text-align: center;
      font-size: 12px;
    }
    .count .sep { color: rgba(255,255,255,0.45); margin: 0 3px; font-weight: 400; }
    .count .total { color: rgba(255,255,255,0.55); }

    .divider {
      width: 1px;
      height: 14px;
      background: rgba(255,255,255,0.18);
      margin: 0 2px;
    }

    /* ── Print: one page per slide, no chrome ────────────────────────────
       The screen layout stacks every slide at inset:0 inside a scaled
       canvas; for print we want them in document flow at the authored
       design size so the browser paginates one slide per sheet. The
       @page size is set from the width/height attributes via the inline
       <style id="deck-stage-print-page"> that connectedCallback injects
       into <head> (the @page at-rule has no effect inside shadow DOM). */
    @media print {
      :host {
        position: static;
        inset: auto;
        background: none;
        overflow: visible;
        color: inherit;
      }
      .stage { position: static; display: block; }
      .canvas {
        transform: none !important;
        width: auto !important;
        height: auto !important;
        background: none;
        will-change: auto;
      }
      ::slotted(*) {
        position: relative !important;
        inset: auto !important;
        width: var(--deck-design-w) !important;
        height: var(--deck-design-h) !important;
        box-sizing: border-box !important;
        opacity: 1 !important;
        visibility: visible !important;
        pointer-events: auto;
        break-after: page;
        page-break-after: always;
        break-inside: avoid;
        overflow: hidden;
      }
      ::slotted(*:last-child) {
        break-after: auto;
        page-break-after: auto;
      }
      .overlay, .tapzones { display: none !important; }
    }
  `;
  class DeckStage extends HTMLElement {
    static get observedAttributes() {
      return ['width', 'height', 'noscale'];
    }
    constructor() {
      super();
      this._root = this.attachShadow({
        mode: 'open'
      });
      this._index = 0;
      this._slides = [];
      this._notes = [];
      this._hideTimer = null;
      this._mouseIdleTimer = null;
      this._storageKey = STORAGE_PREFIX + (location.pathname || '/');
      this._onKey = this._onKey.bind(this);
      this._onResize = this._onResize.bind(this);
      this._onSlotChange = this._onSlotChange.bind(this);
      this._onMouseMove = this._onMouseMove.bind(this);
      this._onTapBack = this._onTapBack.bind(this);
      this._onTapForward = this._onTapForward.bind(this);
    }
    get designWidth() {
      return parseInt(this.getAttribute('width'), 10) || DESIGN_W_DEFAULT;
    }
    get designHeight() {
      return parseInt(this.getAttribute('height'), 10) || DESIGN_H_DEFAULT;
    }
    connectedCallback() {
      this._render();
      this._loadNotes();
      this._syncPrintPageRule();
      window.addEventListener('keydown', this._onKey);
      window.addEventListener('resize', this._onResize);
      window.addEventListener('mousemove', this._onMouseMove, {
        passive: true
      });
      // Initial collection + layout happens via slotchange, which fires on mount.
    }
    disconnectedCallback() {
      window.removeEventListener('keydown', this._onKey);
      window.removeEventListener('resize', this._onResize);
      window.removeEventListener('mousemove', this._onMouseMove);
      if (this._hideTimer) clearTimeout(this._hideTimer);
      if (this._mouseIdleTimer) clearTimeout(this._mouseIdleTimer);
    }
    attributeChangedCallback() {
      if (this._canvas) {
        this._canvas.style.width = this.designWidth + 'px';
        this._canvas.style.height = this.designHeight + 'px';
        this._canvas.style.setProperty('--deck-design-w', this.designWidth + 'px');
        this._canvas.style.setProperty('--deck-design-h', this.designHeight + 'px');
        this._fit();
        this._syncPrintPageRule();
      }
    }
    _render() {
      const style = document.createElement('style');
      style.textContent = stylesheet;
      const stage = document.createElement('div');
      stage.className = 'stage';
      const canvas = document.createElement('div');
      canvas.className = 'canvas';
      canvas.style.width = this.designWidth + 'px';
      canvas.style.height = this.designHeight + 'px';
      canvas.style.setProperty('--deck-design-w', this.designWidth + 'px');
      canvas.style.setProperty('--deck-design-h', this.designHeight + 'px');
      const slot = document.createElement('slot');
      slot.addEventListener('slotchange', this._onSlotChange);
      canvas.appendChild(slot);
      stage.appendChild(canvas);

      // Tap zones (mobile): left third = back, right third = forward.
      const tapzones = document.createElement('div');
      tapzones.className = 'tapzones export-hidden';
      tapzones.setAttribute('aria-hidden', 'true');
      const tzBack = document.createElement('div');
      tzBack.className = 'tapzone tapzone--back';
      const tzMid = document.createElement('div');
      tzMid.className = 'tapzone tapzone--mid';
      tzMid.style.pointerEvents = 'none';
      const tzFwd = document.createElement('div');
      tzFwd.className = 'tapzone tapzone--fwd';
      tzBack.addEventListener('click', this._onTapBack);
      tzFwd.addEventListener('click', this._onTapForward);
      tapzones.append(tzBack, tzMid, tzFwd);

      // Overlay: compact, solid black, with clickable controls.
      const overlay = document.createElement('div');
      overlay.className = 'overlay export-hidden';
      overlay.setAttribute('role', 'toolbar');
      overlay.setAttribute('aria-label', 'Deck controls');
      overlay.innerHTML = `
        <button class="btn prev" type="button" aria-label="Previous slide" title="Previous (←)">
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M10 3L5 8l5 5"/></svg>
        </button>
        <span class="count" aria-live="polite"><span class="current">1</span><span class="sep">/</span><span class="total">1</span></span>
        <button class="btn next" type="button" aria-label="Next slide" title="Next (→)">
          <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M6 3l5 5-5 5"/></svg>
        </button>
        <span class="divider"></span>
        <button class="btn reset" type="button" aria-label="Reset to first slide" title="Reset (R)">Reset<span class="kbd">R</span></button>
      `;
      overlay.querySelector('.prev').addEventListener('click', () => this._go(this._index - 1, 'click'));
      overlay.querySelector('.next').addEventListener('click', () => this._go(this._index + 1, 'click'));
      overlay.querySelector('.reset').addEventListener('click', () => this._go(0, 'click'));
      this._root.append(style, stage, tapzones, overlay);
      this._canvas = canvas;
      this._slot = slot;
      this._overlay = overlay;
      this._countEl = overlay.querySelector('.current');
      this._totalEl = overlay.querySelector('.total');
    }

    /** @page must live in the document stylesheet — it's a no-op inside
     *  shadow DOM. Inject/update a single <head> style tag so the print
     *  sheet matches the design size and Save-as-PDF yields one slide per
     *  page with no margins. */
    _syncPrintPageRule() {
      const id = 'deck-stage-print-page';
      let tag = document.getElementById(id);
      if (!tag) {
        tag = document.createElement('style');
        tag.id = id;
        document.head.appendChild(tag);
      }
      tag.textContent = '@page { size: ' + this.designWidth + 'px ' + this.designHeight + 'px; margin: 0; } ' + '@media print { html, body { margin: 0 !important; padding: 0 !important; background: none !important; overflow: visible !important; height: auto !important; } ' + '* { -webkit-print-color-adjust: exact; print-color-adjust: exact; } }';
    }
    _onSlotChange() {
      this._collectSlides();
      this._restoreIndex();
      this._applyIndex({
        showOverlay: false,
        broadcast: true,
        reason: 'init'
      });
      this._fit();
    }
    _collectSlides() {
      const assigned = this._slot.assignedElements({
        flatten: true
      });
      this._slides = assigned.filter(el => {
        // Skip template/style/script nodes even if someone slots them.
        const tag = el.tagName;
        return tag !== 'TEMPLATE' && tag !== 'SCRIPT' && tag !== 'STYLE';
      });
      this._slides.forEach((slide, i) => {
        const n = i + 1;
        // Determine a label for comment flow: prefer explicit data-label,
        // then an existing data-screen-label, then first heading, else "Slide".
        let label = slide.getAttribute('data-label');
        if (!label) {
          const existing = slide.getAttribute('data-screen-label');
          if (existing) {
            // Strip any leading number the author may have included.
            label = existing.replace(/^\s*\d+\s*/, '').trim() || existing;
          }
        }
        if (!label) {
          const h = slide.querySelector('h1, h2, h3, [data-title]');
          if (h) label = (h.textContent || '').trim().slice(0, 40);
        }
        if (!label) label = 'Slide';
        slide.setAttribute('data-screen-label', `${pad2(n)} ${label}`);

        // Validation attribute for comment flow / auto-checks.
        if (!slide.hasAttribute('data-om-validate')) {
          slide.setAttribute('data-om-validate', VALIDATE_ATTR);
        }
        slide.setAttribute('data-deck-slide', String(i));
      });
      if (this._totalEl) this._totalEl.textContent = String(this._slides.length || 1);
      if (this._index >= this._slides.length) this._index = Math.max(0, this._slides.length - 1);
    }
    _loadNotes() {
      const tag = document.getElementById('speaker-notes');
      if (!tag) {
        this._notes = [];
        return;
      }
      try {
        const parsed = JSON.parse(tag.textContent || '[]');
        if (Array.isArray(parsed)) this._notes = parsed;
      } catch (e) {
        console.warn('[deck-stage] Failed to parse #speaker-notes JSON:', e);
        this._notes = [];
      }
    }
    _restoreIndex() {
      try {
        const raw = localStorage.getItem(this._storageKey);
        if (raw != null) {
          const n = parseInt(raw, 10);
          if (Number.isFinite(n) && n >= 0 && n < this._slides.length) {
            this._index = n;
          }
        }
      } catch (e) {/* ignore */}
    }
    _persistIndex() {
      try {
        localStorage.setItem(this._storageKey, String(this._index));
      } catch (e) {/* ignore */}
    }
    _applyIndex({
      showOverlay = true,
      broadcast = true,
      reason = 'init'
    } = {}) {
      if (!this._slides.length) return;
      const prev = this._prevIndex == null ? -1 : this._prevIndex;
      const curr = this._index;
      this._slides.forEach((s, i) => {
        if (i === curr) s.setAttribute('data-deck-active', '');else s.removeAttribute('data-deck-active');
      });
      if (this._countEl) this._countEl.textContent = String(curr + 1);
      this._persistIndex();
      if (broadcast) {
        // (1) Legacy: host-window postMessage for speaker-notes renderers.
        try {
          window.postMessage({
            slideIndexChanged: curr
          }, '*');
        } catch (e) {}

        // (2) In-page CustomEvent on the <deck-stage> element itself.
        //     Bubbles and composes out of shadow DOM so slide code can listen:
        //       document.querySelector('deck-stage').addEventListener('slidechange', e => {
        //         e.detail.index, e.detail.previousIndex, e.detail.total, e.detail.slide, e.detail.reason
        //       });
        const detail = {
          index: curr,
          previousIndex: prev,
          total: this._slides.length,
          slide: this._slides[curr] || null,
          previousSlide: prev >= 0 ? this._slides[prev] || null : null,
          reason: reason // 'init' | 'keyboard' | 'click' | 'tap' | 'api'
        };
        this.dispatchEvent(new CustomEvent('slidechange', {
          detail,
          bubbles: true,
          composed: true
        }));
      }
      this._prevIndex = curr;
      if (showOverlay) this._flashOverlay();
    }
    _flashOverlay() {
      if (!this._overlay) return;
      this._overlay.setAttribute('data-visible', '');
      if (this._hideTimer) clearTimeout(this._hideTimer);
      this._hideTimer = setTimeout(() => {
        this._overlay.removeAttribute('data-visible');
      }, OVERLAY_HIDE_MS);
    }
    _fit() {
      if (!this._canvas) return;
      // PPTX export sets noscale so the DOM capture sees authored-size
      // geometry — the scaled canvas is in shadow DOM, so the exporter's
      // resetTransformSelector can't reach .canvas.style.transform directly.
      if (this.hasAttribute('noscale')) {
        this._canvas.style.transform = 'none';
        return;
      }
      const vw = window.innerWidth;
      const vh = window.innerHeight;
      const s = Math.min(vw / this.designWidth, vh / this.designHeight);
      this._canvas.style.transform = `scale(${s})`;
    }
    _onResize() {
      this._fit();
    }
    _onMouseMove() {
      // Keep overlay visible while mouse moves; hide after idle.
      this._flashOverlay();
    }
    _onTapBack(e) {
      e.preventDefault();
      this._go(this._index - 1, 'tap');
    }
    _onTapForward(e) {
      e.preventDefault();
      this._go(this._index + 1, 'tap');
    }
    _onKey(e) {
      // Ignore when the user is typing.
      const t = e.target;
      if (t && (t.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(t.tagName))) return;
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const key = e.key;
      let handled = true;
      if (key === 'ArrowRight' || key === 'PageDown' || key === ' ' || key === 'Spacebar') {
        this._go(this._index + 1, 'keyboard');
      } else if (key === 'ArrowLeft' || key === 'PageUp') {
        this._go(this._index - 1, 'keyboard');
      } else if (key === 'Home') {
        this._go(0, 'keyboard');
      } else if (key === 'End') {
        this._go(this._slides.length - 1, 'keyboard');
      } else if (key === 'r' || key === 'R') {
        this._go(0, 'keyboard');
      } else if (/^[0-9]$/.test(key)) {
        // 1..9 jump to that slide; 0 jumps to 10.
        const n = key === '0' ? 9 : parseInt(key, 10) - 1;
        if (n < this._slides.length) this._go(n, 'keyboard');
      } else {
        handled = false;
      }
      if (handled) {
        e.preventDefault();
        this._flashOverlay();
      }
    }
    _go(i, reason = 'api') {
      if (!this._slides.length) return;
      const clamped = Math.max(0, Math.min(this._slides.length - 1, i));
      if (clamped === this._index) {
        this._flashOverlay();
        return;
      }
      this._index = clamped;
      this._applyIndex({
        showOverlay: true,
        broadcast: true,
        reason
      });
    }

    // Public API ------------------------------------------------------------

    /** Current slide index (0-based). */
    get index() {
      return this._index;
    }
    /** Total slide count. */
    get length() {
      return this._slides.length;
    }
    /** Programmatically navigate. */
    goTo(i) {
      this._go(i, 'api');
    }
    next() {
      this._go(this._index + 1, 'api');
    }
    prev() {
      this._go(this._index - 1, 'api');
    }
    reset() {
      this._go(0, 'api');
    }
  }
  if (!customElements.get('deck-stage')) {
    customElements.define('deck-stage', DeckStage);
  }
})();
})(); } catch (e) { __ds_ns.__errors.push({ path: "slides/deck-stage.js", error: String((e && e.message) || e) }); }

// ui_kits/plugin/PluginDetail.jsx
try { (() => {
// plugin/PluginDetail.jsx — centre panel showing plugin overview
function StatusPill({
  tone,
  label
}) {
  const map = {
    active: {
      bg: 'rgba(46,125,50,.1)',
      fg: '#2E7D32'
    },
    working: {
      bg: 'rgba(229,161,0,.12)',
      fg: '#9a6d00'
    },
    idle: {
      bg: 'var(--cw-surface)',
      fg: 'var(--fg-3)'
    }
  };
  const s = map[tone] || map.idle;
  return /*#__PURE__*/React.createElement("span", {
    className: "pw-pill",
    style: {
      background: s.bg,
      color: s.fg
    }
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-pill-dot",
    style: {
      background: s.fg
    }
  }), label);
}
function PluginDetail({
  slug
}) {
  const meta = {
    title: "cogni-sales",
    tagline: "B2B sales pitch generation with the Corporate Visions Why Change methodology.",
    skills: 1,
    agents: 4,
    commands: 2,
    desc: "Generates account-specific pitches using the Why Change arc — four research phases (Why Change, Why Now, Why You, Why Pay) each backed by a dedicated web research agent. Outputs sales-presentation.md and sales-proposal.md with sequential citations."
  };
  return /*#__PURE__*/React.createElement("main", {
    className: "pw-detail"
  }, /*#__PURE__*/React.createElement("header", {
    className: "pw-detail-head"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("p", {
    className: "pw-eyebrow"
  }, "Sales \xB7 Corporate Visions"), /*#__PURE__*/React.createElement("h1", {
    className: "pw-detail-title"
  }, meta.title), /*#__PURE__*/React.createElement("p", {
    className: "pw-detail-tagline"
  }, meta.tagline)), /*#__PURE__*/React.createElement("div", {
    className: "pw-detail-actions"
  }, /*#__PURE__*/React.createElement(StatusPill, {
    tone: "active",
    label: "Active"
  }), /*#__PURE__*/React.createElement("button", {
    className: "cw-btn-primary cw-btn-sm"
  }, "Run pitch \u2192"))), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-row"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-n"
  }, meta.skills), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-l"
  }, "Skill")), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-n"
  }, meta.agents), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-l"
  }, "Agents")), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-n"
  }, meta.commands), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-l"
  }, "Commands")), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-n pw-stat-accent"
  }, "12"), /*#__PURE__*/React.createElement("div", {
    className: "pw-stat-l"
  }, "Runs this week"))), /*#__PURE__*/React.createElement("section", {
    className: "pw-card"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-card-head"
  }, /*#__PURE__*/React.createElement("h3", null, "Why Change arc \xB7 progress"), /*#__PURE__*/React.createElement("span", {
    className: "pw-badge"
  }, "Run #0147 \xB7 Acme Corp")), /*#__PURE__*/React.createElement("div", {
    className: "pw-arc"
  }, [{
    label: "Why Change",
    state: "done",
    agent: "research-why-change"
  }, {
    label: "Why Now",
    state: "done",
    agent: "research-why-now"
  }, {
    label: "Why You",
    state: "active",
    agent: "research-why-you"
  }, {
    label: "Why Pay",
    state: "pending",
    agent: "research-why-pay"
  }].map(p => /*#__PURE__*/React.createElement("div", {
    key: p.label,
    className: "pw-arc-step is-" + p.state
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-arc-dot"
  }), /*#__PURE__*/React.createElement("div", {
    className: "pw-arc-label"
  }, p.label), /*#__PURE__*/React.createElement("div", {
    className: "pw-arc-agent"
  }, p.agent))))), /*#__PURE__*/React.createElement("section", {
    className: "pw-two-col"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-card"
  }, /*#__PURE__*/React.createElement("h3", {
    className: "pw-card-h"
  }, "Outputs"), /*#__PURE__*/React.createElement("ul", {
    className: "pw-file-list"
  }, /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
    className: "pw-file-ic"
  }, "MD"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", null, "sales-presentation.md"), /*#__PURE__*/React.createElement("small", null, "42 citations \xB7 3,480 words")), /*#__PURE__*/React.createElement("span", {
    className: "pw-file-time"
  }, "2m ago")), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
    className: "pw-file-ic"
  }, "MD"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", null, "sales-proposal.md"), /*#__PURE__*/React.createElement("small", null, "28 citations \xB7 2,140 words")), /*#__PURE__*/React.createElement("span", {
    className: "pw-file-time"
  }, "2m ago")), /*#__PURE__*/React.createElement("li", null, /*#__PURE__*/React.createElement("span", {
    className: "pw-file-ic"
  }, "JSON"), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", null, "claims-manifest.json"), /*#__PURE__*/React.createElement("small", null, "70 claims \xB7 ready to verify")), /*#__PURE__*/React.createElement("span", {
    className: "pw-file-time"
  }, "2m ago")))), /*#__PURE__*/React.createElement("div", {
    className: "pw-card"
  }, /*#__PURE__*/React.createElement("h3", {
    className: "pw-card-h"
  }, "Pipeline position"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-step"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-n"
  }, "cogni-portfolio"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-l"
  }, "Upstream")), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-arrow"
  }, "\u2192"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-step is-active"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-n"
  }, "cogni-sales"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-l"
  }, "Current")), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-arrow"
  }, "\u2192"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-step"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-n"
  }, "cogni-visual"), /*#__PURE__*/React.createElement("div", {
    className: "pw-pipe-l"
  }, "Downstream"))), /*#__PURE__*/React.createElement("p", {
    className: "pw-pipe-note"
  }, "Receives portfolio positions; emits presentation-ready narrative to the visual renderer."))));
}
window.PluginDetail = PluginDetail;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/plugin/PluginDetail.jsx", error: String((e && e.message) || e) }); }

// ui_kits/plugin/RunPanel.jsx
try { (() => {
// plugin/RunPanel.jsx — right-side terminal / activity log
const {
  useState: useState_RP,
  useEffect: useEffect_RP
} = React;
const LINES = [{
  t: "→",
  s: "cmd",
  txt: "/pitch --customer=Acme --portfolio=managed-services"
}, {
  t: "·",
  s: "meta",
  txt: "routing to cogni-sales · version 1.4.0"
}, {
  t: "✓",
  s: "ok",
  txt: "why-change agent: 12 sources retrieved (DACH + EN)"
}, {
  t: "✓",
  s: "ok",
  txt: "why-now agent: 8 market signals scored"
}, {
  t: "•",
  s: "run",
  txt: "why-you agent: extracting differentiation claims …"
}, {
  t: "·",
  s: "meta",
  txt: "reading portfolio/acme/positions.json"
}, {
  t: "·",
  s: "meta",
  txt: "17 IS/DOES/MEANS pairs loaded"
}, {
  t: "✓",
  s: "ok",
  txt: "claims manifest seeded with 42 entries"
}, {
  t: "→",
  s: "cmd",
  txt: "/copywrite sales-presentation.md --scope=full"
}, {
  t: "·",
  s: "meta",
  txt: "framework: Pyramid · readability target 50-60"
}, {
  t: "✓",
  s: "ok",
  txt: "readability score: 58.2 · active voice 84%"
}];
function RunPanel() {
  const [i, setI] = useState_RP(6);
  useEffect_RP(() => {
    if (i >= LINES.length) return;
    const t = setTimeout(() => setI(i + 1), 900);
    return () => clearTimeout(t);
  }, [i]);
  return /*#__PURE__*/React.createElement("aside", {
    className: "pw-run"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-run-head"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "pw-run-title"
  }, "Activity"), /*#__PURE__*/React.createElement("div", {
    className: "pw-run-sub"
  }, "Run #0147 \xB7 cogni-sales")), /*#__PURE__*/React.createElement("div", {
    className: "pw-run-status"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-run-dot"
  }), "Streaming")), /*#__PURE__*/React.createElement("div", {
    className: "pw-term"
  }, LINES.slice(0, i).map((l, idx) => /*#__PURE__*/React.createElement("div", {
    key: idx,
    className: "pw-term-line is-" + l.s
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-term-t"
  }, l.t), /*#__PURE__*/React.createElement("span", null, l.txt))), i < LINES.length && /*#__PURE__*/React.createElement("div", {
    className: "pw-term-cursor"
  }, "\u258C")), /*#__PURE__*/React.createElement("div", {
    className: "pw-run-foot"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-chip"
  }, "14s elapsed"), /*#__PURE__*/React.createElement("div", {
    className: "pw-chip"
  }, "$0.04"), /*#__PURE__*/React.createElement("div", {
    className: "pw-chip pw-chip-accent"
  }, "3 / 4 phases")));
}
window.RunPanel = RunPanel;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/plugin/RunPanel.jsx", error: String((e && e.message) || e) }); }

// ui_kits/plugin/Sidebar.jsx
try { (() => {
// plugin/Sidebar.jsx — plugin workspace sidebar
const PLUGINS = [{
  slug: "cogni-research",
  cat: "Research",
  skills: 5,
  agents: 9
}, {
  slug: "cogni-trends",
  cat: "Trends",
  skills: 6,
  agents: 9
}, {
  slug: "cogni-portfolio",
  cat: "Portfolio",
  skills: 19,
  agents: 20
}, {
  slug: "cogni-marketing",
  cat: "Content",
  skills: 11,
  agents: 3
}, {
  slug: "cogni-copywriting",
  cat: "Content",
  skills: 4,
  agents: 2
}, {
  slug: "cogni-sales",
  cat: "Sales",
  skills: 1,
  agents: 4
}, {
  slug: "cogni-visual",
  cat: "Visual",
  skills: 8,
  agents: 17
}, {
  slug: "cogni-website",
  cat: "Website",
  skills: 6,
  agents: 3
}, {
  slug: "cogni-wiki",
  cat: "Platform",
  skills: 7,
  agents: 0
}, {
  slug: "cogni-workspace",
  cat: "Platform",
  skills: 5,
  agents: 0
}];
function PluginSidebar({
  active,
  onSelect
}) {
  return /*#__PURE__*/React.createElement("aside", {
    className: "pw-sidebar"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-brand"
  }, /*#__PURE__*/React.createElement(Mark, {
    size: 32,
    tone: "dark"
  }), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("div", {
    className: "pw-brand-name"
  }, "cogni", /*#__PURE__*/React.createElement("span", {
    className: "hy"
  }, "-"), "work"), /*#__PURE__*/React.createElement("div", {
    className: "pw-brand-sub"
  }, "insight-wave \xB7 v0.4.2"))), /*#__PURE__*/React.createElement("div", {
    className: "pw-side-section"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-side-head"
  }, "Workspace"), /*#__PURE__*/React.createElement("button", {
    className: "pw-side-item is-active"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-side-dot",
    style: {
      background: '#C8E62E'
    }
  }), "Acme \xB7 Consulting"), /*#__PURE__*/React.createElement("button", {
    className: "pw-side-item"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-side-dot",
    style: {
      background: '#6B7280'
    }
  }), "Siemens \xB7 Trends '26")), /*#__PURE__*/React.createElement("div", {
    className: "pw-side-section"
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-side-head"
  }, "Plugins \xB7 10 installed"), PLUGINS.map(p => /*#__PURE__*/React.createElement("button", {
    key: p.slug,
    className: "pw-plugin-item" + (active === p.slug ? " is-active" : ""),
    onClick: () => onSelect(p.slug)
  }, /*#__PURE__*/React.createElement("div", {
    className: "pw-plugin-main"
  }, /*#__PURE__*/React.createElement("span", {
    className: "pw-plugin-slug"
  }, p.slug), /*#__PURE__*/React.createElement("span", {
    className: "pw-plugin-cat"
  }, p.cat)), /*#__PURE__*/React.createElement("div", {
    className: "pw-plugin-meta"
  }, p.skills, "\xB7", p.agents)))), /*#__PURE__*/React.createElement("div", {
    className: "pw-side-foot"
  }, /*#__PURE__*/React.createElement("button", {
    className: "pw-side-mini"
  }, "\u2699 Workspace health")));
}
window.PluginSidebar = PluginSidebar;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/plugin/Sidebar.jsx", error: String((e && e.message) || e) }); }

// ui_kits/shared/Mark.jsx
try { (() => {
// Mark.jsx — chartreuse triangle mark, point-up equilateral
// Props: size (px, default 32), tone ('light'|'dark' — dark inverts to outline on dark backgrounds)
function Mark({
  size = 32,
  tone = 'light',
  style = {}
}) {
  const fill = '#C8E62E';
  return /*#__PURE__*/React.createElement("svg", {
    width: size,
    height: size,
    viewBox: "0 0 60 60",
    "aria-hidden": "true",
    style: {
      flexShrink: 0,
      ...style
    }
  }, /*#__PURE__*/React.createElement("polygon", {
    points: "30,6 56,52 4,52",
    fill: fill
  }));
}
window.Mark = Mark;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/shared/Mark.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/AudienceTabs.jsx
try { (() => {
// website/AudienceTabs.jsx — tabbed audience section
const {
  useState: useState_AT
} = React;
const AUDIENCES = [{
  key: "consulting",
  label: "Consulting firms",
  head: "You compete on methodology depth, not headcount.",
  sub: "Every pitch costs days of senior capacity. We give that time back.",
  points: ["Account-specific pitches in 90 minutes", "Verified research reports in under 20", "60 scored trend candidates per scouting run", "Double Diamond with automated phase gates"],
  cta: "Start with cogni-sales"
}, {
  key: "sales",
  label: "Sales organizations",
  head: "Standard decks stop working after the third customer.",
  sub: "Methodology-disciplined pitches, without tying up senior capacity on every deal.",
  points: ["Full Corporate Visions arc per opportunity", "DACH-grade account briefings reps can stand behind", "Buyer-role-specific value propositions", "Battle cards, demo scripts, objection handlers on tap"],
  cta: "Start with cogni-portfolio"
}, {
  key: "marketing",
  label: "Marketing teams",
  head: "Your pipeline needs more content. Your budget doesn't.",
  sub: "16 channel-ready formats from a single narrative source — in consistent brand voice.",
  points: ["One narrative → blog, LinkedIn, whitepaper, newsletter", "Source-verified thought leadership, no invented stats", "Trend-driven relevance via TIPS scouting", "Website pages from the same content engine"],
  cta: "Start with cogni-marketing"
}];
function AudienceTabs() {
  const [tab, setTab] = useState_AT("consulting");
  const cur = AUDIENCES.find(a => a.key === tab);
  return /*#__PURE__*/React.createElement("section", {
    className: "cw-section cw-section-alt",
    id: "who"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-section-inner"
  }, /*#__PURE__*/React.createElement("p", {
    className: "cw-eyebrow"
  }, "Who it's for"), /*#__PURE__*/React.createElement("h2", {
    className: "cw-section-h"
  }, "Built for three kinds of team."), /*#__PURE__*/React.createElement("div", {
    className: "cw-tabs"
  }, AUDIENCES.map(a => /*#__PURE__*/React.createElement("button", {
    key: a.key,
    className: "cw-tab" + (tab === a.key ? " is-active" : ""),
    onClick: () => setTab(a.key)
  }, a.label))), /*#__PURE__*/React.createElement("div", {
    className: "cw-aud-panel"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("h3", {
    className: "cw-aud-head"
  }, cur.head), /*#__PURE__*/React.createElement("p", {
    className: "cw-aud-sub"
  }, cur.sub), /*#__PURE__*/React.createElement("a", {
    className: "cw-link-accent",
    href: "#"
  }, cur.cta, " \u2192")), /*#__PURE__*/React.createElement("ul", {
    className: "cw-aud-list"
  }, cur.points.map((p, i) => /*#__PURE__*/React.createElement("li", {
    key: i
  }, /*#__PURE__*/React.createElement("span", {
    className: "cw-check"
  }, "\u2713"), p))))));
}
window.AudienceTabs = AudienceTabs;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/AudienceTabs.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/CTAFooter.jsx
try { (() => {
// website/CTAFooter.jsx — CTA band + footer
function CTAFooter() {
  return /*#__PURE__*/React.createElement(React.Fragment, null, /*#__PURE__*/React.createElement("section", {
    className: "cw-cta-band",
    id: "get-started"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-section-inner cw-cta-band-inner"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("p", {
    className: "cw-eyebrow cw-eyebrow-accent"
  }, "Next steps"), /*#__PURE__*/React.createElement("h2", {
    className: "cw-section-h cw-section-h-light"
  }, "Ready to work", /*#__PURE__*/React.createElement("br", null), /*#__PURE__*/React.createElement("span", {
    className: "cw-accent"
  }, "smarter?"))), /*#__PURE__*/React.createElement("div", {
    className: "cw-cta-actions"
  }, /*#__PURE__*/React.createElement("p", {
    className: "cw-cta-note"
  }, "Install the marketplace, run your first infographic in 15 minutes. Everything runs on your laptop \u2014 GDPR-compliant by design."), /*#__PURE__*/React.createElement("div", {
    className: "cw-cta-row"
  }, /*#__PURE__*/React.createElement("a", {
    className: "cw-btn-primary cw-btn-lg",
    href: "#"
  }, "Get started \u2192"), /*#__PURE__*/React.createElement("a", {
    className: "cw-btn-ghost-dark",
    href: "#services"
  }, "Talk to services"))))), /*#__PURE__*/React.createElement("footer", {
    className: "cw-footer"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-section-inner cw-footer-inner"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-footer-brand"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-brand cw-brand-light"
  }, /*#__PURE__*/React.createElement(Mark, {
    size: 28,
    tone: "dark"
  }), /*#__PURE__*/React.createElement("span", null, "cogni", /*#__PURE__*/React.createElement("span", {
    className: "hy"
  }, "-"), "work", /*#__PURE__*/React.createElement("span", {
    className: "tld"
  }, ".ai"))), /*#__PURE__*/React.createElement("p", {
    className: "cw-footer-motto"
  }, "Firmitas \xB7 Utilitas \xB7 Venustas"), /*#__PURE__*/React.createElement("p", {
    className: "cw-footer-tiny"
  }, "\xA9 2026 cogni-work.ai \xB7 AGPL-3.0")), /*#__PURE__*/React.createElement("div", {
    className: "cw-footer-col"
  }, /*#__PURE__*/React.createElement("h4", null, "Platform"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Plugins"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Workflows"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Architecture"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Changelog")), /*#__PURE__*/React.createElement("div", {
    className: "cw-footer-col"
  }, /*#__PURE__*/React.createElement("h4", null, "For teams"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Consulting firms"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Sales orgs"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Marketing"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Professional services")), /*#__PURE__*/React.createElement("div", {
    className: "cw-footer-col"
  }, /*#__PURE__*/React.createElement("h4", null, "Community"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "GitHub"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Contributing"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Partner program"), /*#__PURE__*/React.createElement("a", {
    href: "#"
  }, "Security")))));
}
window.CTAFooter = CTAFooter;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/CTAFooter.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/CapabilitySection.jsx
try { (() => {
// website/CapabilitySection.jsx — card grid of capability areas
const CAPABILITIES = [{
  area: "Research",
  plug: "cogni-research",
  desc: "5–25 parallel web research agents producing cited, structured reports.",
  skills: 5,
  agents: 9
}, {
  area: "Trend Intelligence",
  plug: "cogni-trends",
  desc: "TIPS scouting with bilingual DE/EN research and investment theme modeling.",
  skills: 6,
  agents: 9
}, {
  area: "Portfolio Messaging",
  plug: "cogni-portfolio",
  desc: "IS/DOES/MEANS positioning across eight industry taxonomies.",
  skills: 19,
  agents: 20
}, {
  area: "Content Production",
  plug: "cogni-marketing",
  desc: "16 channel-ready formats from a single narrative foundation.",
  skills: 11,
  agents: 3
}, {
  area: "Sales Pitches",
  plug: "cogni-sales",
  desc: "Corporate Visions Why Change methodology with account-specific research.",
  skills: 1,
  agents: 4
}, {
  area: "Visual Production",
  plug: "cogni-visual",
  desc: "Slide decks, web narratives, poster storyboards, infographics.",
  skills: 8,
  agents: 17
}];
function CapabilityCard({
  item,
  highlight
}) {
  return /*#__PURE__*/React.createElement("article", {
    className: "cw-cap-card" + (highlight ? " is-highlight" : "")
  }, /*#__PURE__*/React.createElement("p", {
    className: "cw-cap-slug"
  }, item.plug), /*#__PURE__*/React.createElement("h3", {
    className: "cw-cap-h"
  }, item.area), /*#__PURE__*/React.createElement("p", {
    className: "cw-cap-desc"
  }, item.desc), /*#__PURE__*/React.createElement("div", {
    className: "cw-cap-foot"
  }, /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", null, item.skills), " skills"), /*#__PURE__*/React.createElement("span", null, /*#__PURE__*/React.createElement("b", null, item.agents), " agents")));
}
function CapabilitySection() {
  return /*#__PURE__*/React.createElement("section", {
    className: "cw-section",
    id: "plugins"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-section-inner"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-section-head"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("p", {
    className: "cw-eyebrow"
  }, "The platform"), /*#__PURE__*/React.createElement("h2", {
    className: "cw-section-h"
  }, "Six capability areas.", /*#__PURE__*/React.createElement("br", null), "One consistent foundation.")), /*#__PURE__*/React.createElement("p", {
    className: "cw-section-sub"
  }, "Every plugin implements an established framework \u2014 Corporate Visions, Double Diamond, TIPS, IS/DOES/MEANS \u2014 rather than general-purpose text generation.")), /*#__PURE__*/React.createElement("div", {
    className: "cw-cap-grid"
  }, CAPABILITIES.map((c, i) => /*#__PURE__*/React.createElement(CapabilityCard, {
    key: c.plug,
    item: c,
    highlight: i === 2
  })))));
}
window.CapabilitySection = CapabilitySection;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/CapabilitySection.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Hero.jsx
try { (() => {
// website/Hero.jsx — dark full-bleed hero
function Hero() {
  return /*#__PURE__*/React.createElement("section", {
    className: "cw-hero",
    id: "platform"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-hero-grid",
    "aria-hidden": "true"
  }, [8, 18, 28, 38, 50, 62, 72, 82, 92].map((l, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      left: l + '%'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    className: "cw-hero-inner"
  }, /*#__PURE__*/React.createElement("p", {
    className: "cw-eyebrow cw-eyebrow-accent"
  }, "Firmitas \xB7 Utilitas \xB7 Venustas"), /*#__PURE__*/React.createElement("h1", {
    className: "cw-hero-h1"
  }, "Smarter ", /*#__PURE__*/React.createElement("span", {
    className: "cw-accent"
  }, "knowledge"), /*#__PURE__*/React.createElement("br", null), "work for professional teams."), /*#__PURE__*/React.createElement("p", {
    className: "cw-hero-lede"
  }, "An open-source platform of 14 Claude Code plugins for consulting, sales, and marketing \u2014 grounded in established methodology, cited by design, reproducible end to end."), /*#__PURE__*/React.createElement("div", {
    className: "cw-hero-actions"
  }, /*#__PURE__*/React.createElement("a", {
    className: "cw-btn-primary",
    href: "#get-started"
  }, "Get started \u2192"), /*#__PURE__*/React.createElement("a", {
    className: "cw-btn-ghost-dark",
    href: "#plugins"
  }, "See the plugins")), /*#__PURE__*/React.createElement("dl", {
    className: "cw-hero-stats"
  }, /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("dt", null, "14"), /*#__PURE__*/React.createElement("dd", null, "Open-source plugins")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("dt", null, "91"), /*#__PURE__*/React.createElement("dd", null, "Composable skills")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("dt", null, "74"), /*#__PURE__*/React.createElement("dd", null, "Specialist agents")), /*#__PURE__*/React.createElement("div", null, /*#__PURE__*/React.createElement("dt", null, "AGPL"), /*#__PURE__*/React.createElement("dd", null, "3.0, always")))));
}
window.Hero = Hero;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Hero.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/MetricsBand.jsx
try { (() => {
// website/MetricsBand.jsx — dark band with hero metrics
function MetricsBand() {
  return /*#__PURE__*/React.createElement("section", {
    className: "cw-metrics-band"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-hero-grid",
    "aria-hidden": "true"
  }, [10, 22, 34, 48, 60, 72, 84].map((l, i) => /*#__PURE__*/React.createElement("span", {
    key: i,
    style: {
      left: l + '%'
    }
  }))), /*#__PURE__*/React.createElement("div", {
    className: "cw-section-inner"
  }, /*#__PURE__*/React.createElement("p", {
    className: "cw-eyebrow cw-eyebrow-accent"
  }, "What teams report"), /*#__PURE__*/React.createElement("h2", {
    className: "cw-section-h cw-section-h-light"
  }, "Methodology depth,", /*#__PURE__*/React.createElement("br", null), "without the overhead."), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-row"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-metric"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-num"
  }, "3.2", /*#__PURE__*/React.createElement("span", {
    className: "u"
  }, "\xD7")), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-lab"
  }, "Faster insight discovery"), /*#__PURE__*/React.createElement("p", {
    className: "cw-metric-note"
  }, "From scattered search to structured, cited retrieval.")), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-num"
  }, "47", /*#__PURE__*/React.createElement("span", {
    className: "u"
  }, "%")), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-lab"
  }, "Less coordination time"), /*#__PURE__*/React.createElement("p", {
    className: "cw-metric-note"
  }, "Automated workflows replace status chasing.")), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-num"
  }, "5", /*#__PURE__*/React.createElement("span", {
    className: "u"
  }, "h")), /*#__PURE__*/React.createElement("div", {
    className: "cw-metric-lab"
  }, "Saved / consultant / week"), /*#__PURE__*/React.createElement("p", {
    className: "cw-metric-note"
  }, "Reclaimed for high-value analysis.")))));
}
window.MetricsBand = MetricsBand;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/MetricsBand.jsx", error: String((e && e.message) || e) }); }

// ui_kits/website/Nav.jsx
try { (() => {
// website/Nav.jsx — top marketing nav
const {
  useState
} = React;
function Nav() {
  const [open, setOpen] = useState(false);
  return /*#__PURE__*/React.createElement("header", {
    className: "cw-nav"
  }, /*#__PURE__*/React.createElement("div", {
    className: "cw-nav-inner"
  }, /*#__PURE__*/React.createElement("a", {
    className: "cw-brand",
    href: "#"
  }, /*#__PURE__*/React.createElement(Mark, {
    size: 28,
    tone: "light"
  }), /*#__PURE__*/React.createElement("span", null, "cogni", /*#__PURE__*/React.createElement("span", {
    className: "hy"
  }, "-"), "work", /*#__PURE__*/React.createElement("span", {
    className: "tld"
  }, ".ai"))), /*#__PURE__*/React.createElement("nav", {
    className: "cw-nav-links"
  }, /*#__PURE__*/React.createElement("a", {
    href: "#platform"
  }, "Platform"), /*#__PURE__*/React.createElement("a", {
    href: "#plugins"
  }, "Plugins"), /*#__PURE__*/React.createElement("a", {
    href: "#who"
  }, "Who it's for"), /*#__PURE__*/React.createElement("a", {
    href: "#services"
  }, "Services"), /*#__PURE__*/React.createElement("a", {
    href: "https://github.com/cogni-work/insight-wave",
    target: "_blank",
    rel: "noreferrer"
  }, "Docs")), /*#__PURE__*/React.createElement("div", {
    className: "cw-nav-cta"
  }, /*#__PURE__*/React.createElement("a", {
    className: "cw-nav-signin",
    href: "#"
  }, "Sign in"), /*#__PURE__*/React.createElement("a", {
    className: "cw-btn-primary cw-btn-sm",
    href: "#get-started"
  }, "Get started \u2192"))));
}
window.Nav = Nav;
})(); } catch (e) { __ds_ns.__errors.push({ path: "ui_kits/website/Nav.jsx", error: String((e && e.message) || e) }); }

__ds_ns.CogniWorkThemeShowcase = __ds_scope.CogniWorkThemeShowcase;

})();
