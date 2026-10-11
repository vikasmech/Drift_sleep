import React from 'react';
import { Platform } from 'react-native';
import { Feather } from '@expo/vector-icons';
import { isLiquidGlassAvailable } from 'expo-glass-effect';
import { Tabs } from 'expo-router';
import { NativeTabs } from 'expo-router/unstable-native-tabs';
import { SymbolView } from 'expo-symbols';
import { useColors } from '@/hooks/useColors';

const TABS = [
  { name: 'index', label: 'Tonight', sf: 'moon', sfSel: 'moon.fill', feather: 'moon' },
  { name: 'sounds', label: 'Sounds', sf: 'waveform', sfSel: 'waveform', feather: 'music' },
  { name: 'favourites', label: 'Favourites', sf: 'heart', sfSel: 'heart.fill', feather: 'heart' },
  { name: 'settings', label: 'Settings', sf: 'slider.horizontal.3', sfSel: 'slider.horizontal.3', feather: 'sliders' },
] as const;

function NativeTabLayout() {
  return (
    <NativeTabs>
      {TABS.map((t) => (
        <NativeTabs.Trigger key={t.name} name={t.name}>
          <NativeTabs.Trigger.Icon sf={{ default: t.sf, selected: t.sfSel }} />
          <NativeTabs.Trigger.Label>{t.label}</NativeTabs.Trigger.Label>
        </NativeTabs.Trigger>
      ))}
    </NativeTabs>
  );
}

function ClassicTabLayout() {
  const colors = useColors();
  const isIOS = Platform.OS === 'ios';
  const isWeb = Platform.OS === 'web';
  return (
    <Tabs
      screenOptions={{
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.mutedForeground,
        tabBarStyle: {
          backgroundColor: colors.card,
          borderTopWidth: 1,
          borderTopColor: colors.border,
          elevation: 0,
          ...(isWeb ? { height: 84 } : {}),
        },
        tabBarLabelStyle: { fontFamily: 'Figtree_500Medium', fontSize: 11 },
      }}
    >
      {TABS.map((t) => (
        <Tabs.Screen
          key={t.name}
          name={t.name}
          options={{
            title: t.label,
            tabBarIcon: ({ color }) =>
              isIOS ? <SymbolView name={t.sf} tintColor={color} size={24} /> : <Feather name={t.feather} size={22} color={color} />,
          }}
        />
      ))}
    </Tabs>
  );
}

export default function TabLayout() {
  if (isLiquidGlassAvailable()) return <NativeTabLayout />;
  return <ClassicTabLayout />;
}
