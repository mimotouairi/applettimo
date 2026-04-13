import { Module } from '@nestjs/common';
import { StoryController } from './stories.controller';
import { StoryService } from './stories.service';
import { CloudinaryModule } from '../cloudinary/cloudinary.module';

@Module({
  imports: [CloudinaryModule],
  controllers: [StoryController],
  providers: [StoryService],
})
export class StoryModule {}
