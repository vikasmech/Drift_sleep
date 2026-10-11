import * as FileSystem from 'expo-file-system/legacy';
import { audioFilename, audioUrl, getSound } from '../constants/sounds';

const directory = `${FileSystem.documentDirectory ?? ''}drift-audio/`;
const pending = new Map<string, Promise<string>>();
export const localAudioPath = (id: string) => `${directory}${audioFilename(id)}`;

/**
 * Fully cache a lossless loop before handing it to the native queue player.
 * Shared downloads prevent Play and Save All from writing the same file at once.
 */
export function ensureLoopDownloaded(id: string, progress: (fraction: number) => void): Promise<string> {
  if (!getSound(id)?.free) return Promise.reject(new Error('Only free sounds can be cached.'));
  const existing = pending.get(id);
  if (existing) return existing;
  const finalPath = localAudioPath(id);
  const tmp = `${finalPath}.part`;
  const job = (async () => {
    const info = await FileSystem.getInfoAsync(finalPath);
    if (info.exists && (info.size ?? 0) > 44) return finalPath;
    await FileSystem.makeDirectoryAsync(directory, { intermediates: true });
    const dl = FileSystem.createDownloadResumable(audioUrl(id), tmp, {}, (event) => {
      const total = event.totalBytesExpectedToWrite;
      progress(total > 0 ? Math.min(0.99, event.totalBytesWritten / total) : 0);
    });
    try {
      const result = await dl.downloadAsync();
      if (!result || result.status !== 200) throw new Error('Continuous audio download failed.');
      const contentType = Object.entries(result.headers ?? {}).find(([key]) => key.toLowerCase() === 'content-type')?.[1];
      if (!contentType || !/^audio\/(?:wav|wave|x-wav)(?:;|$)/i.test(contentType)) {
        throw new Error('The server did not return a lossless audio file.');
      }
      const saved = await FileSystem.getInfoAsync(tmp);
      if (!saved.exists || (saved.size ?? 0) <= 44) throw new Error('Audio download was empty.');
      await FileSystem.deleteAsync(finalPath, { idempotent: true });
      await FileSystem.moveAsync({ from: tmp, to: finalPath });
      // Only retire the old MP3 after its replacement has been safely saved.
      await FileSystem.deleteAsync(`${directory}native-${id}.mp3`, { idempotent: true }).catch(() => {});
      progress(1);
      return finalPath;
    } catch (error) {
      await FileSystem.deleteAsync(tmp, { idempotent: true }).catch(() => {});
      throw error;
    }
  })();
  pending.set(id, job);
  void job.then(() => pending.delete(id), () => pending.delete(id));
  return job;
}
