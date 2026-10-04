export const QUEUES = {
  pushSend: 'push-send',
  dmPush: 'dm-push-send',
  followerFanout: 'follower-fanout',
  mediaProcess: 'media-process',
  exportGenerate: 'export-generate',
  liveRecordAutoEnd: 'live-record-auto-end',
} as const;

export type QueueName = (typeof QUEUES)[keyof typeof QUEUES];
export const ALL_QUEUES: QueueName[] = Object.values(QUEUES);
