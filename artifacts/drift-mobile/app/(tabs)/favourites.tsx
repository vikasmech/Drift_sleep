import React from 'react';
import { Text, View } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { Body, fonts, Screen, SoundRow } from '@/components/ui';
import { useColors } from '@/hooks/useColors';
import { useAudio } from '@/context/AudioContext';
import { getSound, Soundscape } from '@/constants/sounds';

export default function Favourites() {
  const c = useColors();
  const { favourites, hydrated } = useAudio();
  const items = favourites.map(getSound).filter((x): x is Soundscape => !!x);
  return (
    <Screen title="Favourites" subtitle="Sounds you keep coming back to.">
      <View style={{ height: 20 }} />
      {!hydrated ? (
        [0, 1, 2].map((i) => <View key={i} style={{ height: 66, borderRadius: c.radius, backgroundColor: c.card, marginBottom: 10 }} />)
      ) : items.length === 0 ? (
        <View style={{ alignItems: 'center', paddingVertical: 56, gap: 12 }}>
          <Feather name="heart" size={32} color={c.mutedForeground} />
          <Text style={{ color: c.foreground, fontFamily: fonts.serifRegular, fontSize: 20 }}>Nothing saved yet</Text>
          <View style={{ maxWidth: 260 }}><Body>Tap the heart on any sound and it will wait for you here.</Body></View>
        </View>
      ) : (
        items.map((x) => <SoundRow key={x.id} sound={x} />)
      )}
    </Screen>
  );
}
