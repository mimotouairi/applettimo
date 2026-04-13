import { Injectable, NotFoundException, BadRequestException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ChatGateway } from '../chat/chat.gateway';
import { CloudinaryService } from '../cloudinary/cloudinary.service';

@Injectable()
export class PostService {
  constructor(
    private prisma: PrismaService,
    private chatGateway: ChatGateway,
    private cloudinary: CloudinaryService
  ) {}
  private postViewsTableAvailable = true;

  private calculateEngagementScore(post: any) {
    const likesCount = post._count?.likes || 0;
    const commentsCount = post._count?.comments || 0;
    const viewsCount = post._count?.views || 0;
    const createdAt = new Date(post.createdAt);
    const ageHours = Math.max(
      1,
      (Date.now() - createdAt.getTime()) / (1000 * 60 * 60),
    );
    const recencyBoost = 48 / (ageHours + 2);
    return Number(
      (likesCount * 2.5 + commentsCount * 3.5 + viewsCount * 0.7 + recencyBoost)
        .toFixed(2),
    );
  }

  private formatPostForFlutter(post: any) {
    const viewsCount = post._count?.views || 0;
    const engagementScore =
      post.engagement_score ?? this.calculateEngagementScore(post);

    return {
      id: post.id?.toString(),
      user_id: post.userId?.toString(),
      name: post.user?.name,
      username: post.user?.username,
      photo: post.user?.photo,
      content: post.content,
      image_url: post.mediaUrl,
      media_urls: post.mediaItems ? post.mediaItems.map((m: any) => m.url) : (post.mediaUrl ? [post.mediaUrl] : []),
      media_type: post.mediaType,
      likes: post._count?.likes || 0,
      comments_count: post._count?.comments || 0,
      views_count: viewsCount,
      engagement_score: engagementScore,
      created_at: post.createdAt,
      time: post.createdAt?.toISOString(),
      isLiked: post.likes && post.likes.length > 0,
      repost_id: post.repostId?.toString(),
      original_post: post.repost ? this.formatPostForFlutter(post.repost) : null
    };
  }

  async getPosts(user_id: string, limit: string = '10', offset: string = '0') {
    if (!user_id || isNaN(parseInt(user_id))) return [];

    let posts: any[] = [];
    try {
      posts = await this.prisma.post.findMany({
        take: parseInt(limit),
        skip: parseInt(offset),
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true, views: true } },
          likes: { where: { userId: parseInt(user_id) } },
          repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
          ,
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
      this.postViewsTableAvailable = true;
    } catch (error: any) {
      if (error?.code !== 'P2021') {
        throw error;
      }
      this.postViewsTableAvailable = false;
      posts = await this.prisma.post.findMany({
        take: parseInt(limit),
        skip: parseInt(offset),
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true } },
          likes: { where: { userId: parseInt(user_id) } },
          repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
          ,
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
    }

    const sortedPosts = posts
      .map((post: any) => ({
        ...post,
        engagement_score: this.calculateEngagementScore(post),
      }))
      .sort((a: any, b: any) => b.engagement_score - a.engagement_score);

    return sortedPosts.map((post: any) => this.formatPostForFlutter(post));
  }

  async getVideos(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];

    let posts: any[] = [];
    try {
      posts = await this.prisma.post.findMany({
        where: {
          OR: [
            { mediaType: { contains: 'video' } },
            { mediaUrl: { contains: '.mp4' } },
            { mediaUrl: { contains: 'cloudinary' } }
          ]
        },
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true, views: true } },
          likes: { where: { userId: parseInt(user_id) } }
          ,
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
      this.postViewsTableAvailable = true;
    } catch (error: any) {
      if (error?.code !== 'P2021') {
        throw error;
      }
      this.postViewsTableAvailable = false;
      posts = await this.prisma.post.findMany({
        where: {
          OR: [
            { mediaType: { contains: 'video' } },
            { mediaUrl: { contains: 'cloudinary' } }
          ]
        },
        orderBy: { createdAt: 'desc' },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true } },
          likes: { where: { userId: parseInt(user_id) } }
          ,
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });
    }

    return posts.map(post => this.formatPostForFlutter(post));
  }

  private async notifyMentions(content: string, actorId: number, postId?: number, commentId?: number) {
    if (!content) return;
    const mentions = content.match(/@(\w+)/g);
    if (!mentions) return;

    const usernames = mentions.map(m => m.substring(1));
    const users = await this.prisma.user.findMany({
      where: { username: { in: usernames } },
      select: { id: true }
    });

    const actor = await this.prisma.user.findUnique({
      where: { id: actorId },
      select: { id: true, name: true, photo: true }
    });

    for (const user of users) {
      if (user.id === actorId) continue;

      const notification = await this.prisma.notification.create({
        data: {
          userId: user.id,
          actorId,
          type: 'mention',
          title: 'إشارة جديدة',
          body: `قام ${actor?.name} بالإشارة إليك`,
          postId,
          commentId,
        }
      });

      this.chatGateway.emitNotification(user.id.toString(), {
        ...notification,
        id: notification.id.toString(),
        actor
      });
    }
  }

  async createPostWithCloudinary(data: any, file?: Express.Multer.File) {
    try {
      const { user_id, content, privacy, media_type } = data;
      console.log(`[PostService] Creating post for user: ${user_id}`);
      
      let url = null;
      let type = media_type || 'text';

      if (file) {
        const result = await this.cloudinary.uploadFile(file);
        url = result.secure_url;
        type = file.mimetype.startsWith('video') ? 'video' : 'image';
      }

      const post = await this.prisma.post.create({
        data: {
          userId: parseInt(user_id),
          content,
          privacy: privacy || 'public',
          mediaType: type,
          mediaUrl: url
        },
        include: {
          user: { select: { id: true, name: true, username: true, photo: true } },
          _count: { select: { likes: true, comments: true } },
          mediaItems: { orderBy: { position: 'asc' } },
        }
      });

      if (content) {
        this.notifyMentions(content, parseInt(user_id), post.id);
      }

      console.log(`[PostService] Post created successfully: ${post.id}`);
      return this.formatPostForFlutter(post);
    } catch (error) {
      console.error('[PostService] Error creating post:', error);
      throw error;
    }
  }

  async createPostMultiWithCloudinary(data: any, files: Express.Multer.File[] = []) {
    const { user_id, content, privacy } = data;
    const uploadPromises = files.map(file => this.cloudinary.uploadFile(file));
    const uploadResults = await Promise.all(uploadPromises);
    const urls = uploadResults.map(res => res.secure_url);

    const hasVideo = files.some((f) => f.mimetype.startsWith('video'));
    const mediaType = hasVideo ? 'video' : (files.length > 0 ? 'image' : 'text');

    const post = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        content,
        privacy: privacy || 'public',
        mediaType,
        mediaUrl: urls.length > 0 ? urls[0] : null,
        mediaItems: {
          create: urls.map((url, index) => ({
            url,
            mediaType: files[index].mimetype.startsWith('video') ? 'video' : 'image',
            position: index,
          })),
        },
      },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true, views: true } },
        likes: { where: { userId: parseInt(user_id) } },
        mediaItems: { orderBy: { position: 'asc' } },
      },
    });

    if (content) {
      this.notifyMentions(content, parseInt(user_id), post.id);
    }

    return this.formatPostForFlutter(post);
  }

  async createPost(data: any, file?: any) {
    return this.createPostWithCloudinary(data, file);
  }

  async createPostMulti(data: any, files: Express.Multer.File[] = []) {
    return this.createPostMultiWithCloudinary(data, files);
  }

  async repostPost(user_id: string, post_id: string) {
    const originalPost = await this.prisma.post.findUnique({ where: { id: parseInt(post_id) } });
    if (!originalPost) throw new NotFoundException('المنشور غير موجود');

    const newPost = await this.prisma.post.create({
      data: {
        userId: parseInt(user_id),
        repostId: parseInt(post_id),
        privacy: 'public',
        mediaType: 'text',
      }
    });
    return { success: true, message: 'تم إعادة النشر بنجاح' };
  }

  async toggleLike(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingLike = await this.prisma.like.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingLike) {
      await this.prisma.like.delete({ where: { id: existingLike.id } });
      return { message: 'Like removed', isLiked: false };
    } else {
      await this.prisma.like.create({ data: { userId: uid, postId: pid } });
      const post = await this.prisma.post.findUnique({ where: { id: pid } });
      if (post && post.userId !== uid) {
        const notification = await this.prisma.notification.create({
          data: {
            userId: post.userId,
            actorId: uid,
            type: 'like',
            title: 'إعجاب جديد',
            body: 'أعجب أحد المستخدمين بمنشورك',
            postId: pid,
          },
        });

        const actor = await this.prisma.user.findUnique({
          where: { id: uid },
          select: { id: true, name: true, photo: true }
        });

        this.chatGateway.emitNotification(post.userId.toString(), {
          ...notification,
          id: notification.id.toString(),
          actor
        });
      }
      return { message: 'Post liked', isLiked: true };
    }
  }

  async toggleSave(user_id: string, post_id: string) {
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const existingSave = await this.prisma.savedPost.findUnique({
      where: { userId_postId: { userId: uid, postId: pid } }
    });

    if (existingSave) {
      await this.prisma.savedPost.delete({ where: { id: existingSave.id } });
      return { message: 'Save removed', saved: false };
    } else {
      await this.prisma.savedPost.create({ data: { userId: uid, postId: pid } });
      return { message: 'Post saved', saved: true };
    }
  }

  async markView(user_id: string, post_id: string) {
    if (!this.postViewsTableAvailable) {
      return { views_count: 0 };
    }

    const uid = parseInt(user_id);
    const pid = parseInt(post_id);

    if (Number.isNaN(uid) || Number.isNaN(pid)) {
      throw new BadRequestException('معرف المستخدم أو المنشور غير صالح');
    }

    try {
      await this.prisma.postView.upsert({
        where: { userId_postId: { userId: uid, postId: pid } },
        update: { createdAt: new Date() },
        create: { userId: uid, postId: pid },
      });
    } catch (error: any) {
      if (error?.code === 'P2021') {
        this.postViewsTableAvailable = false;
        return { views_count: 0 };
      }
      throw error;
    }

    const post = await this.prisma.post.findUnique({
      where: { id: pid },
      include: { _count: { select: { views: true } } },
    });

    if (!post) {
      throw new NotFoundException('المنشور غير موجود');
    }

    return { views_count: post._count.views };
  }

  async getSavedPosts(user_id: string) {
    if (!user_id || isNaN(parseInt(user_id))) return [];
    
    const saved = await this.prisma.savedPost.findMany({
      where: { userId: parseInt(user_id) },
      include: {
        post: {
          include: {
            user: { select: { id: true, name: true, username: true, photo: true } },
            _count: { select: { likes: true, comments: true } },
            likes: { where: { userId: parseInt(user_id) } },
            repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } }
            ,
            mediaItems: { orderBy: { position: 'asc' } },
          }
        }
      },
      orderBy: { createdAt: 'desc' }
    });

    return saved.map(s => this.formatPostForFlutter(s.post));
  }

  async getPostById(user_id: string, post_id: string) {
    if (!user_id || isNaN(parseInt(user_id)) || !post_id || isNaN(parseInt(post_id))) {
      throw new BadRequestException('معرف المستخدم أو المنشور غير صالح');
    }
    const uid = parseInt(user_id);
    const pid = parseInt(post_id);
    const post = await this.prisma.post.findUnique({
      where: { id: pid },
      include: {
        user: { select: { id: true, name: true, username: true, photo: true } },
        _count: { select: { likes: true, comments: true, views: true } },
        likes: { where: { userId: uid } },
        repost: { include: { user: true, _count: { select: { likes: true, comments: true } } } },
        mediaItems: { orderBy: { position: 'asc' } },
      },
    });
    if (!post) {
      throw new NotFoundException('المنشور غير موجود');
    }
    return this.formatPostForFlutter(post);
  }

  async deletePost(user_id: string, post_id: string) {
    const post = await this.prisma.post.findUnique({ where: { id: parseInt(post_id) } });
    if (!post) throw new NotFoundException('المنشور غير موجود');
    if (post.userId !== parseInt(user_id)) throw new ForbiddenException('غير مصرح لك بحذف هذا المنشور');
    
    await this.prisma.post.delete({ where: { id: post.id } });
    return { message: 'تم حذف المنشور بنجاح' };
  }
}
