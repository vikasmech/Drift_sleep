import React from 'react';
import { ActivityIndicator, Platform, Pressable, StyleSheet, Text, View } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColors } from '@/hooks/useColors';
import { useAudio, useTimerRemaining } from '@/context/AudioContext';
import { getSound } from '@/constants/sounds';
import { fmt, fonts } from '@/components/ui';

function Countdown() {
  const c = useColors();
  const left = useTimerRemaining();
  const { timerMinutes } = useAudio();
  const text = left != null ? `Sleep timer: ${fmt(left)} left` : timerMinutes > 0 ? `Timer set for ${timerMinutes} min, starts when sound plays` : 'Sleep timer off';
  return <Text style={{ color: c.mutedForeground, fontFamily: fonts.sans, fontSize: 14 }}>{text}</Text>;
}

export default function Tonight() {
  const c = useColors();
  const insets = useSafeAreaInsets();
  const { usualId, currentId, status, errorMessage, toggle, stop, hydrated } = useAudio();
  const usual = getSound(usualId)!;
  const showing = currentId && status !== 'idle' ? getSound(currentId)! : usual;
  const on = currentId === showing.id && (status === 'playing' || status === 'loading');
  const loading = currentId === showing.id && status === 'loading';
  const err = currentId === showing.id && status === 'error';
  const ended = currentId === showing.id && status === 'ended';
  const top = Platform.OS === 'web' ? 67 : insets.top;
  const bottom = Platform.OS === 'web' ? 34 : 0;
  return (
    <View style={{ flex: 1, backgroundColor: c.background, paddingTop: top + 16, paddingBottom: bottom + 24, paddingHorizontal: 24 }}>
      <Text style={{ color: c.mutedForeground, fontFamily: fonts.sansMedium, fontSize: 14, letterSpacing: 1.2 }}>TONIGHT</Text>
      <View style={s.center}>
        <Text style={{ color: c.foreground, fontFamily: fonts.serif, fontSize: 34, textAlign: 'center' }}>{showing.title}</Text>
        <Text style={{ color: c.mutedForeground, fontFamily: fonts.sans, fontSize: 15, textAlign: 'center', marginTop: 8, marginBottom: 36, lineHeight: 22 }}>
          {showing.description}
        </Text>
        <View style={[s.ring, { borderColor: c.accent }]}>
          <Pressable
            testID="tonight-play"
            accessibilityRole="button"
            accessibilityLabel={on ? `Pause ${showing.title}` : `Play ${showing.title}`}
            disabled={!hydrated}
            onPress={() => toggle(showing.id)}
            style={({ pressed }) => [s.btn, { backgroundColor: c.primary, opacity: pressed ? 0.8 : hydrated ? 1 : 0.4 }]}
          >
            {loading ? <ActivityIndicator color={c.primaryForeground} size="large" />
              : <Feather name={err || ended ? 'rotate-cw' : on ? 'pause' : 'play'} size={44} color={c.primaryForeground} />}
          </Pressable>
        </View>
        <View style={{ height: 52, marginTop: 28, alignItems: 'center', justifyContent: 'center' }}>
          {err ? (
            <Text style={{ color: c.destructive, fontFamily: fonts.sansMedium, textAlign: 'center' }}>
              {errorMessage ?? 'Could not play.'} Tap to retry.
            </Text>
          ) : ended ? (
            <Text style={{ color: c.mutedForeground, fontFamily: fonts.sans }}>Preview ended.</Text>
          ) : <Countdown />}
        </View>
      </View>
      <View style={{ minHeight: 48, alignItems: 'center' }}>
        {currentId && status !== 'idle' ? (
          <Pressable testID="tonight-stop" accessibilityRole="button" accessibilityLabel="Stop" onPress={stop}
            style={[s.stop, { borderColor: c.border, borderRadius: c.radius }]}>
            <Feather name="square" size={14} color={c.foreground} />
            <Text style={{ color: c.foreground, fontFamily: fonts.sansMedium }}>Stop</Text>
          </Pressable>
        ) : null}
      </View>
    </View>
  );
}

const s = StyleSheet.create({
  center: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  ring: { width: 188, height: 188, borderRadius: 94, borderWidth: 1, alignItems: 'center', justifyContent: 'center' },
  btn: { width: 148, height: 148, borderRadius: 74, alignItems: 'center', justifyContent: 'center' },
  stop: { flexDirection: 'row', gap: 8, alignItems: 'center', paddingHorizontal: 22, minHeight: 44, borderWidth: 1 },
});
