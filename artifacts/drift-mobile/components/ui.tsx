import React, { ReactNode } from 'react';
import { ActivityIndicator, Platform, Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColors } from '@/hooks/useColors';
import { useAudio } from '@/context/AudioContext';
import { getSound, Soundscape } from '@/constants/sounds';

export const fonts = {
  sans: 'Figtree_400Regular',
  sansMedium: 'Figtree_500Medium',
  sansSemi: 'Figtree_600SemiBold',
  serif: 'Fraunces_300Light',
  serifRegular: 'Fraunces_400Regular',
};

export function Screen({ title, subtitle, children }: { title: string; subtitle?: string; children: ReactNode }) {
  const c = useColors();
  const insets = useSafeAreaInsets();
  const top = Platform.OS === 'web' ? 67 : insets.top;
  const bottom = Platform.OS === 'web' ? 34 : 0;
  return (
    <View style={{ flex: 1, backgroundColor: c.background }}>
      <ScrollView
        contentInsetAdjustmentBehavior="never"
        contentContainerStyle={{ paddingTop: top + 16, paddingBottom: bottom + 32, paddingHorizontal: 20 }}
        showsVerticalScrollIndicator={false}
      >
        <Text style={[s.title, { color: c.foreground, fontFamily: fonts.serif }]}>{title}</Text>
        {subtitle ? <Text style={[s.sub, { color: c.mutedForeground, fontFamily: fonts.sans }]}>{subtitle}</Text> : null}
        <NowBar />
        {children}
      </ScrollView>
    </View>
  );
}

/** Compact now-playing control with stop. Renders nothing when idle. */
export function NowBar() {
  const c = useColors();
  const { currentId, status, errorMessage, toggle, stop } = useAudio();
  const snd = currentId ? getSound(currentId) : null;
  if (!snd || status === 'idle') return null;
  const label =
    status === 'loading' ? 'Loading' : status === 'playing' ? 'Playing' : status === 'paused' ? 'Paused'
    : status === 'ended' ? 'Preview ended' : 'Could not play';
  return (
    <View style={[s.now, { backgroundColor: c.card, borderColor: status === 'error' ? c.destructive : c.border, borderRadius: c.radius }]}>
      <View style={{ flex: 1 }}>
        <Text style={[s.nowTitle, { color: c.foreground, fontFamily: fonts.sansSemi }]}>{snd.title}</Text>
        <Text style={{ color: status === 'error' ? c.destructive : c.mutedForeground, fontFamily: fonts.sans, fontSize: 13 }}>
          {status === 'error' && errorMessage ? errorMessage : label}
        </Text>
      </View>
      <IconBtn
        testID="nowbar-toggle"
        label={status === 'error' ? 'Retry' : 'Play or pause'}
        name={status === 'error' || status === 'ended' ? 'rotate-cw' : status === 'playing' || status === 'loading' ? 'pause' : 'play'}
        onPress={() => toggle(snd.id)}
      />
      <IconBtn testID="nowbar-stop" label="Stop" name="square" onPress={stop} />
    </View>
  );
}

export function IconBtn({ name, onPress, label, color, testID, filled }: {
  name: React.ComponentProps<typeof Feather>['name']; onPress: () => void; label: string; color?: string; testID?: string; filled?: boolean;
}) {
  const c = useColors();
  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityLabel={label}
      hitSlop={6}
      onPress={onPress}
      style={({ pressed }) => [s.iconBtn, { opacity: pressed ? 0.5 : 1, backgroundColor: filled ? c.secondary : 'transparent', borderRadius: c.radius }]}
    >
      <Feather name={name} size={20} color={color ?? c.foreground} />
    </Pressable>
  );
}

export function SoundRow({ sound }: { sound: Soundscape }) {
  const c = useColors();
  const { currentId, status, toggle, favourites, toggleFavourite } = useAudio();
  const active = currentId === sound.id && status !== 'idle';
  const busy = active && status === 'loading';
  const on = active && (status === 'playing' || status === 'loading');
  const fav = favourites.includes(sound.id);
  return (
    <Pressable
      testID={`sound-${sound.id}`}
      accessibilityRole="button"
      accessibilityLabel={`${on ? 'Pause' : 'Play'} ${sound.title}`}
      onPress={() => toggle(sound.id)}
      style={({ pressed }) => [s.row, { backgroundColor: active ? c.accent : c.card, borderColor: c.border, borderRadius: c.radius, opacity: pressed ? 0.8 : 1 }]}
    >
      <View style={[s.dot, { backgroundColor: sound.color }]}>
        {busy ? <ActivityIndicator size="small" color={c.background} /> : <Feather name={on ? 'pause' : 'play'} size={16} color={c.background} />}
      </View>
      <View style={{ flex: 1 }}>
        <Text style={{ color: c.foreground, fontFamily: fonts.sansSemi, fontSize: 16 }}>{sound.title}</Text>
        <Text numberOfLines={1} style={{ color: c.mutedForeground, fontFamily: fonts.sans, fontSize: 13, marginTop: 2 }}>
          {sound.free ? 'Free, loops all night' : '30 second preview'} / {sound.category}
        </Text>
      </View>
      <IconBtn
        testID={`fav-${sound.id}`}
        label={fav ? `Remove ${sound.title} from favourites` : `Add ${sound.title} to favourites`}
        name="heart"
        color={fav ? c.primary : c.mutedForeground}
        onPress={() => toggleFavourite(sound.id)}
      />
    </Pressable>
  );
}

export function Chip({ label, selected, onPress, testID }: { label: string; selected: boolean; onPress: () => void; testID?: string }) {
  const c = useColors();
  return (
    <Pressable
      testID={testID}
      accessibilityRole="button"
      accessibilityState={{ selected }}
      onPress={onPress}
      style={[s.chip, { borderRadius: c.radius, backgroundColor: selected ? c.primary : c.secondary, borderColor: selected ? c.primary : c.border }]}
    >
      <Text style={{ color: selected ? c.primaryForeground : c.foreground, fontFamily: fonts.sansMedium, fontSize: 14 }}>{label}</Text>
    </Pressable>
  );
}

export function Card({ children }: { children: ReactNode }) {
  const c = useColors();
  return <View style={[s.card, { backgroundColor: c.card, borderColor: c.border, borderRadius: c.radius }]}>{children}</View>;
}

export function H2({ children }: { children: ReactNode }) {
  const c = useColors();
  return <Text style={{ color: c.foreground, fontFamily: fonts.serifRegular, fontSize: 21, marginTop: 28, marginBottom: 10 }}>{children}</Text>;
}

export function Body({ children }: { children: ReactNode }) {
  const c = useColors();
  return <Text style={{ color: c.mutedForeground, fontFamily: fonts.sans, fontSize: 14, lineHeight: 21 }}>{children}</Text>;
}

export const fmt = (ms: number) => {
  const t = Math.ceil(ms / 1000);
  const h = Math.floor(t / 3600), m = Math.floor((t % 3600) / 60), sec = t % 60;
  return h > 0 ? `${h}:${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}` : `${m}:${String(sec).padStart(2, '0')}`;
};

const s = StyleSheet.create({
  title: { fontSize: 34, letterSpacing: -0.3 },
  sub: { fontSize: 15, marginTop: 4, lineHeight: 22 },
  now: { flexDirection: 'row', alignItems: 'center', gap: 4, padding: 14, borderWidth: 1, marginTop: 18 },
  nowTitle: { fontSize: 16 },
  iconBtn: { width: 44, height: 44, alignItems: 'center', justifyContent: 'center' },
  row: { flexDirection: 'row', alignItems: 'center', gap: 14, padding: 12, borderWidth: 1, marginBottom: 10 },
  dot: { width: 40, height: 40, borderRadius: 20, alignItems: 'center', justifyContent: 'center' },
  chip: { paddingHorizontal: 16, minHeight: 44, justifyContent: 'center', borderWidth: 1 },
  card: { padding: 16, borderWidth: 1 },
});
