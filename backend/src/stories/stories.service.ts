import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class StoryService {
  constructor(
    private prisma: PrismaService,
    private cloudinary: CloudinaryService
  ) {}

  async getStories(userId: number) {
    const stories = await this.prisma.story.findMany({
      where: {
        OR: [
          { userId },
          { user: { followers: { some: { followerId: userId } } } },
        ],
        createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) },
      },
      include: {
        user: { select: { id: true, name: true, photo: true, username: true } },
        _count: { select: { views: true, likes: true } },
        likes: { where: { userId } },
      },
      orderBy: { createdAt: 'desc' },
    });

    const grouped = stories.reduce((acc: any, story) => {
      const uId = story.userId.toString();
      if (!acc[uId]) {
        acc[uId] = {
          user_id: uId,
          name: story.user.name,
          photo: story.user.photo,
          stories: [],
        };
      }
      acc[uId].stories.push({
        id: story.id.toString(),
        media_url: story.mediaUrl,
        media_type: story.mediaType,
        created_at: story.createdAt,
        isLiked: story.likes.length > 0,
        views: story._count.views,
        likes: story._count.likes,
      });
      return acc;
    }, {});

    return Object.values(grouped);
  }

  async addStoryWithCloudinary(userId: number, file: Express.Multer.File, mediaType: string) {
    try {
      console.log(`[StoryService] Adding story for user: ${userId}`);
      const result = await this.cloudinary.uploadFile(file);
      
      const story = await this.prisma.story.create({
        data: {
          userId,
          mediaUrl: result.secure_url,
          mediaType,
        },
      });

      console.log(`[StoryService] Story created successfully: ${story.id}`);
      return story;
    } catch (error) {
      console.error('[StoryService] Error adding story:', error);
      throw error;
    }
  }

  async addStory(userId: number, mediaUrl: string, mediaType: string) {
    return this.prisma.story.create({
      data: {
        userId,
        mediaUrl,
        mediaType,
      },
    });
  }

  async toggleLike(userId: number, storyId: number) {
    const existing = await this.prisma.storyLike.findUnique({
      where: { userId_storyId: { userId, storyId } },
    });

    if (existing) {
      await this.prisma.storyLike.delete({ where: { id: existing.id } });
      return { liked: false };
    } else {
      await this.prisma.storyLike.create({ data: { userId, storyId } });
      return { liked: true };
    }
  }

  async markViewed(userId: number, storyId: number) {
    return this.prisma.storyView.upsert({
      where: { userId_storyId: { userId, storyId } },
      create: { userId, storyId },
      update: {},
    });
  }
}
