import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { PostModule } from './posts/post.module';
import { UserModule } from './users/user.module';
import { StoryModule } from './stories/stories.module';
import { ChatModule } from './chat/chat.module';
import { CommentModule } from './comments/comments.module';
import { MulterModule } from '@nestjs/platform-express';
import { CloudinaryModule } from './cloudinary/cloudinary.module';

@Module({
  imports: [
    PrismaModule,
    AuthModule,
    CloudinaryModule,
    PostModule,
    UserModule,
    StoryModule,
    ChatModule,
    CommentModule,
    MulterModule.register({
      dest: './uploads',
      limits: {
        fileSize: 100 * 1024 * 1024, // 100MB
      },
    }),
  ],
  controllers: [AppController],
})
export class AppModule {}
