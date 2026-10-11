// Tokens derived exactly from artifacts/drift/src/index.css (HSL triplets), night is the only mode.
function hsl(h: number, s: number, l: number): string {
  const sn = s / 100, ln = l / 100;
  const a = sn * Math.min(ln, 1 - ln);
  const f = (n: number) => {
    const k = (n + h / 30) % 12;
    const v = ln - a * Math.max(-1, Math.min(k - 3, 9 - k, 1));
    return Math.round(v * 255).toString(16).padStart(2, '0');
  };
  return `#${f(0)}${f(8)}${f(4)}`;
}

const night = {
  text: hsl(38, 40, 90),
  tint: hsl(38, 72, 72),
  background: hsl(233, 40, 8),
  foreground: hsl(38, 40, 90),
  card: hsl(233, 34, 12),
  cardForeground: hsl(38, 40, 90),
  primary: hsl(38, 72, 72),
  primaryForeground: hsl(233, 40, 10),
  secondary: hsl(233, 30, 17),
  secondaryForeground: hsl(38, 40, 90),
  muted: hsl(233, 28, 15),
  mutedForeground: hsl(232, 18, 66),
  accent: hsl(250, 34, 24),
  accentForeground: hsl(38, 40, 92),
  destructive: hsl(8, 60, 58),
  destructiveForeground: hsl(0, 0, 98),
  border: hsl(233, 26, 18),
  input: hsl(233, 24, 24),
};

const colors = {
  light: night,
  dark: night,
  radius: 16,
};

export default colors;
