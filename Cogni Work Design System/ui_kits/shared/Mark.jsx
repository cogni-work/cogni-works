// Mark.jsx — chartreuse triangle mark, point-up equilateral
// Props: size (px, default 32), tone ('light'|'dark' — dark inverts to outline on dark backgrounds)
function Mark({ size = 32, tone = 'light', style = {} }) {
  const fill = '#C8E62E';
  return (
    <svg width={size} height={size} viewBox="0 0 60 60" aria-hidden="true" style={{ flexShrink: 0, ...style }}>
      {/* point-up equilateral triangle, inset 6px */}
      <polygon points="30,6 56,52 4,52" fill={fill}/>
    </svg>
  );
}
window.Mark = Mark;
