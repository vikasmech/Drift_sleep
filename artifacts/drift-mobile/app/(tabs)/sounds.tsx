import React from 'react';
import { Text, View } from 'react-native';
import { Body, Card, fonts, H2, Screen, SoundRow } from '@/components/ui';
import { useColors } from '@/hooks/useColors';
import { CATEGORIES, sounds } from '@/constants/sounds';

export default function Sounds() {
  const c = useColors();
  const free = sounds.filter((x) => x.free);
  return (
    <Screen title="Sounds" subtitle="Thirty to choose from. Tap one and put the phone down.">
      <H2>Free for everyone</H2>
      {free.map((x) => <SoundRow key={x.id} sound={x} />)}
      <View style={{ height: 8 }} />
      <Card>
        <Text style={{ color: c.foreground, fontFamily: fonts.sansSemi, fontSize: 16, marginBottom: 6 }}>The full collection</Text>
        <Body>
          The other 25 sounds are planned as a one-time purchase. Payments are not enabled yet, so for now
          each one plays as a 30 second preview that fades out and does not loop.
        </Body>
      </Card>
      {CATEGORIES.map((cat) => {
        const items = sounds.filter((x) => !x.free && x.category === cat);
        if (!items.length) return null;
        return (
          <View key={cat}>
            <H2>{cat}</H2>
            {items.map((x) => <SoundRow key={x.id} sound={x} />)}
          </View>
        );
      })}
    </Screen>
  );
}
