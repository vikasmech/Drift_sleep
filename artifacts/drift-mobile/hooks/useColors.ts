import colors from '@/constants/colors';

/** Drift is night-only: one palette regardless of system appearance. */
export function useColors() {
  return { ...colors.dark, radius: colors.radius };
}
