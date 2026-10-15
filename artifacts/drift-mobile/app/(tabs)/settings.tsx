import React from 'react';
import { ActivityIndicator, Pressable, StyleSheet, Text, View } from 'react-native';
import Slider from '@react-native-community/slider';
import { Body, Card, Chip, fonts, H2, IconBtn, Screen } from '@/components/ui';
import { useColors } from '@/hooks/useColors';
import { TIMER_OPTIONS, useAudio } from '@/context/AudioContext';
import { FREE_SOUNDS } from '@/constants/sounds';

export default function Settings() {
  const c = useColors();
  const a = useAudio();
  const readyCount = FREE_SOUNDS.filter((x) => a.offlineReady[x.id]).length;
  const anyBusy = Object.keys(a.downloadProgress).length > 0;
  return (
    <Screen title="Settings">
      <H2>Your usual sound</H2>
      <Body>The one Tonight plays. Only the five free sounds can be your usual.</Body>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8, marginTop: 12 }}>
        {FREE_SOUNDS.map((x) => (
          <Chip key={x.id} testID={`usual-${x.id}`} label={x.title} selected={a.usualId === x.id} onPress={() => a.setUsual(x.id)} />
        ))}
      </View>

      <H2>Sleep timer</H2>
      <View style={{ flexDirection: 'row', flexWrap: 'wrap', gap: 8 }}>
        {TIMER_OPTIONS.map((m) => (
          <Chip key={m} testID={`timer-${m}`} label={m === 0 ? 'Off' : `${m} min`} selected={a.timerMinutes === m} onPress={() => a.setTimerMinutes(m)} />
        ))}
      </View>
      <View style={{ height: 8 }} />
      <Body>Sound fades for a few seconds, then stops. The timer starts each time you press play.</Body>

      <H2>Volume</H2>
      <Slider
        testID="volume-slider"
        accessibilityLabel="Volume"
        style={{ height: 44 }}
        minimumValue={0}
        maximumValue={1}
        value={a.volume}
        onSlidingComplete={a.setVolume}
        onValueChange={a.setVolume}
        minimumTrackTintColor={c.primary}
        maximumTrackTintColor={c.input}
        thumbTintColor={c.primary}
      />

      <H2>Offline listening</H2>
      {!a.offlineSupported ? (
        <Card><Body>Offline listening is available in the iPhone app only. This preview always streams.</Body></Card>
      ) : (
        <>
          <Body>{readyCount} of {FREE_SOUNDS.length} free sounds saved on this phone.
            {'\n'}Each sound saves automatically on first play, so repeats do not need a connection.
            Older downloads need one refresh to use the new continuous loops.</Body>
          <View style={{ height: 12 }} />
          {FREE_SOUNDS.map((x) => {
            const ready = !!a.offlineReady[x.id];
            const prog = a.downloadProgress[x.id];
            const err = a.downloadErrors[x.id];
            return (
              <View key={x.id} style={{ flexDirection: 'row', alignItems: 'center', paddingVertical: 10, minHeight: 56, borderBottomWidth: StyleSheet.hairlineWidth, borderBottomColor: c.border }}>
                <View style={{ flex: 1 }}>
                  <Text style={{ color: c.foreground, fontFamily: fonts.sansMedium, fontSize: 15 }}>{x.title}</Text>
                  <Text style={{ color: err ? c.destructive : c.mutedForeground, fontFamily: fonts.sans, fontSize: 13 }}>
                    {err ?? (prog != null ? `Downloading ${Math.round(prog * 100)}%` : ready ? 'Saved on this phone' : 'Saves on first play')}
                  </Text>
                  {prog != null ? (
                    <View style={{ height: 3, borderRadius: 2, backgroundColor: c.input, marginTop: 6 }}>
                      <View style={{ height: 3, borderRadius: 2, backgroundColor: c.primary, width: `${Math.round(prog * 100)}%` }} />
                    </View>
                  ) : null}
                </View>
                {prog != null ? <ActivityIndicator color={c.primary} style={{ width: 44 }} />
                  : ready ? <IconBtn testID={`remove-${x.id}`} label={`Remove ${x.title} download`} name="trash-2" onPress={() => a.removeDownload(x.id)} />
                  : <IconBtn testID={`download-${x.id}`} label={err ? `Retry ${x.title} download` : `Download ${x.title}`} name={err ? 'rotate-cw' : 'download'} onPress={() => a.download(x.id)} />}
              </View>
            );
          })}
          <Pressable
            testID="download-all"
            accessibilityRole="button"
            disabled={anyBusy || readyCount === FREE_SOUNDS.length}
            onPress={a.downloadAll}
            style={{ marginTop: 16, minHeight: 48, borderRadius: c.radius, backgroundColor: c.card, alignItems: 'center', justifyContent: 'center', opacity: anyBusy || readyCount === FREE_SOUNDS.length ? 0.45 : 1 }}
          >
            <Text style={{ color: c.foreground, fontFamily: fonts.sansSemi }}>
              {readyCount === FREE_SOUNDS.length ? 'All five saved' : 'Save all five'}
            </Text>
          </Pressable>
        </>
      )}

      <H2>Good to know</H2>
      <Card>
        <Body>
          Native audio is configured for playback with the screen locked, with play and pause controls.
          This still needs real-iPhone verification before we promise overnight reliability.{'\n\n'}
          The sleep timer runs on the phone. Whether it stops precisely through a whole night still needs
          testing on a real iPhone, so do not rely on it to the minute.{'\n\n'}
          Only the five free sounds loop and can be saved offline. The other 25 are 30 second previews and
          need a connection. A one-time purchase for them is planned, but payments are not enabled yet.{'\n\n'}
          Rain, ocean, forest and ambient audio are AI-generated. Noise and fan sounds are synthesized.
          The collection includes softened tonal variations, not 30 separate field recordings.{'\n\n'}
          No account is needed. Favourites, preferences and downloads stay on this device and are
          removed if you delete the app or clear its storage.
        </Body>
      </Card>
    </Screen>
  );
}
