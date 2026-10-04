import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma/prisma.service';

@Injectable()
export class SettingsService {
  constructor(private readonly prisma: PrismaService) {}

  async getAll(userId: string) {
    const [notifications, privacy, app] = await Promise.all([
      this.prisma.userNotificationPreferences.findUnique({ where: { userId } }),
      this.prisma.userPrivacyPreferences.findUnique({ where: { userId } }),
      this.prisma.userAppPreferences.findUnique({ where: { userId } }),
    ]);
    return { notifications, privacy, app };
  }

  patchNotifications(userId: string, data: any) {
    return this.prisma.userNotificationPreferences.upsert({ where: { userId }, create: { userId, ...data }, update: data });
  }
  patchPrivacy(userId: string, data: any) {
    return this.prisma.userPrivacyPreferences.upsert({ where: { userId }, create: { userId, ...data }, update: data });
  }
  async patchApp(userId: string, languageCode: string) {
    await this.prisma.user.update({ where: { id: userId }, data: { languageCode } });
    return this.prisma.userAppPreferences.upsert({
      where: { userId },
      create: { userId, languageCode },
      update: { languageCode },
    });
  }

  async softDeleteAccount(userId: string) {
    const permanentDeleteAt = new Date(Date.now() + 30 * 24 * 3600 * 1000);
    await this.prisma.user.update({ where: { id: userId }, data: { deletedAt: new Date(), permanentDeleteAt } });
  }
}
