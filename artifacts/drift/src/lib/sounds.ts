export type Category = "Rain" | "Water" | "Noise" | "Nature" | "Music";
export interface Soundscape {
  id: string;
  title: string;
  description: string;
  category: Category;
  free: boolean;
  color: string;
  art: string;
  kind: string;
}

const palette: Record<Category, string> = {
  Rain: "#647d9a", Water: "#4d9290", Noise: "#ab8fbd", Nature: "#6c957a", Music: "#c59975",
};
const entries: [string, string, string, Category, string][] = [
  ["gentle-rain", "Gentle rain", "A soft, steady shower. Nothing to think about.", "Rain", "rain"],
  ["ocean-waves", "Ocean waves", "Slow surf rolling onto a quiet shore.", "Water", "ocean"],
  ["brown-noise", "Brown noise", "Deep, warm noise that settles into the background.", "Noise", "brown"],
  ["pink-noise", "Pink noise", "Balanced, softly textured noise.", "Noise", "pink"],
  ["soft-fan", "Soft fan", "A familiar, low whirr for your bedside.", "Noise", "fan"],
  ["rain-on-glass", "Rain on glass", "A softened shower, as heard through a window.", "Rain", "rain-glass"],
  ["warm-rain", "Warm rain", "A deeper, muted rainfall texture.", "Rain", "rain-warm"],
  ["distant-rain", "Distant rain", "Rainfall softened by distance.", "Rain", "rain-distant"],
  ["evening-shower", "Evening shower", "A lighter veil of falling rain.", "Rain", "rain-light"],
  ["rainy-room", "Rainy room", "A sheltered, warm version of gentle rain.", "Rain", "rain-room"],
  ["quiet-cove", "Quiet cove", "A gentler, sheltered ocean wash.", "Water", "ocean-cove"],
  ["distant-surf", "Distant surf", "The low wash of a faraway shoreline.", "Water", "ocean-distant"],
  ["moonlit-sea", "Moonlit sea", "A wide, slow ocean texture.", "Water", "ocean-moon"],
  ["soft-tide", "Soft tide", "A warm, softened tide.", "Water", "ocean-soft"],
  ["deep-water", "Deep water", "Deep layers of flowing sound.", "Water", "ocean-deep"],
  ["white-noise", "White noise", "Even, full-spectrum masking noise.", "Noise", "white"],
  ["velvet-noise", "Velvet noise", "A very soft, low-frequency noise bed.", "Noise", "velvet"],
  ["warm-static", "Warm static", "Gentle filtered static without sharp edges.", "Noise", "static"],
  ["cabin-fan", "Cabin fan", "A deeper fan texture with a steady hum.", "Noise", "fan-deep"],
  ["airflow", "Airflow", "An airy, smooth background hush.", "Noise", "air"],
  ["night-forest", "Night forest", "Soft crickets and a breeze through leaves.", "Nature", "forest"],
  ["woodland-hush", "Woodland hush", "A muted version of the nighttime forest.", "Nature", "forest-hush"],
  ["distant-crickets", "Distant crickets", "A lighter, distant nocturnal texture.", "Nature", "forest-distant"],
  ["sheltered-grove", "Sheltered grove", "A warm, enclosed woodland ambience.", "Nature", "forest-grove"],
  ["evening-breeze", "Evening breeze", "Soft leaves and a filtered evening hush.", "Nature", "forest-breeze"],
  ["soft-ambient", "Soft ambient", "Slow, warm instrumental pads. No beat.", "Music", "music"],
  ["low-glow", "Low glow", "A deeper, softer ambient layer.", "Music", "music-low"],
  ["quiet-orbit", "Quiet orbit", "An airy edit of the ambient collection.", "Music", "music-air"],
  ["stillness", "Stillness", "Gentle sustained chords, softly filtered.", "Music", "music-still"],
  ["last-light", "Last light", "A warm, close version of the ambient pads.", "Music", "music-warm"],
];

export const sounds: Soundscape[] = entries.map(([id, title, description, category, kind], i) => ({
  id, title, description, category, kind, free: i < 5, color: palette[category], art: category.toLowerCase(),
}));
