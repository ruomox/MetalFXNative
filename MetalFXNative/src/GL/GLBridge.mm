//
//  GLBridge.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/18.
//

#define GL_SILENCE_DEPRECATION

#import "GLBridge.h"
#import "IOSurfaceBridge.h"
#import "Logger.h"

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/CGLCurrent.h>
#import <OpenGL/CGLIOSurface.h>

// Helper: create a framebuffer and attach given texture. returns fbo (0 = fail)
static GLuint createFramebufferWithTexture(GLuint tex) {
    GLuint fbo = 0;
    glGenFramebuffers(1, &fbo);
    if (fbo == 0) return 0;
    glBindFramebuffer(GL_FRAMEBUFFER, fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        LOG_ERROR("GLBridge", [[NSString stringWithFormat:@"创建 FBO 失败：status=0x%04x", status] UTF8String]);
        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        glDeleteFramebuffers(1, &fbo);
        return 0;
    }
    return fbo;
}

uint32_t GLBridge_BindTextureToSurface(GLuint srcTexture, int width, int height) {
    if (srcTexture == 0 || width <= 0 || height <= 0) {
        LOG_ERROR("GLBridge", "BindTextureToSurface: 参数无效");
        return 0;
    }

    // 必须在正确的 OpenGL context 下调用
    CGLContextObj ctx = CGLGetCurrentContext();
    if (!ctx) {
        LOG_ERROR("GLBridge", "BindTextureToSurface: 当前没有有效的 CGL Context");
        return 0;
    }

    // 创建 IOSurface (由 IOSurfaceBridge 管理生命周期)
    IOSurfaceRef surface = IOSurfaceBridge_CreateIOSurfaceWithWidth(width, height);
    if (!surface) {
        LOG_ERROR("GLBridge", "BindTextureToSurface: 创建 IOSurface 失败");
        return 0;
    }

    // 绑定源纹理
    glBindTexture(GL_TEXTURE_2D, srcTexture);
    // 设置基本参数以保证可渲染
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

    // 将当前绑定的纹理和 IOSurface 关联起来（零拷贝）
    // 注意：internalFormat, format, type 参数需与你纹理实际格式对应，Minecraft 常用 BGRA/UNORM
    CGLTexImageIOSurface2D(ctx,
                           GL_TEXTURE_2D,
                           GL_RGBA,                        // internal format
                           (GLsizei)width,
                           (GLsizei)height,
                           GL_BGRA,                        // format
                           GL_UNSIGNED_INT_8_8_8_8_REV,    // type
                           surface,
                           0);

    // 不在此处释放 surface（上层应在合适时机调用 IOSurfaceBridge_Release）
    uint32_t sid = IOSurfaceGetID(surface);
    LOG_INFO("GLBridge", [[NSString stringWithFormat:@"BindTextureToSurface 成功：tex=%u -> surfaceID=%u (%dx%d)", srcTexture, sid, width, height] UTF8String]);

    // 返回 surface id，供 Java / Metal 使用
    return sid;
}

uint32_t GLBridge_BlitTextureToSurface(GLuint srcTexture, int width, int height) {
    if (srcTexture == 0 || width <= 0 || height <= 0) {
        LOG_ERROR("GLBridge", "BlitTextureToSurface: 参数无效");
        return 0;
    }

    CGLContextObj ctx = CGLGetCurrentContext();
    if (!ctx) {
        LOG_ERROR("GLBridge", "BlitTextureToSurface: 当前没有有效的 CGL Context");
        return 0;
    }

    // 1) 创建目标 IOSurface
    IOSurfaceRef surface = IOSurfaceBridge_CreateIOSurfaceWithWidth(width, height);
    if (!surface) {
        LOG_ERROR("GLBridge", "BlitTextureToSurface: 创建 IOSurface 失败");
        return 0;
    }

    // 2) 为 IOSurface 创建一个 GL 纹理（目标纹理）
    GLuint dstTex = 0;
    glGenTextures(1, &dstTex);
    glBindTexture(GL_TEXTURE_2D, dstTex);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
    glPixelStorei(GL_UNPACK_ALIGNMENT, 4);

    // 把 dstTex 关联到 IOSurface
    CGLTexImageIOSurface2D(ctx,
                           GL_TEXTURE_2D,
                           GL_RGBA,
                           (GLsizei)width,
                           (GLsizei)height,
                           GL_BGRA,
                           GL_UNSIGNED_INT_8_8_8_8_REV,
                           surface,
                           0);

    // 3) 创建两个 FBO：一个绑定 srcTexture（read），一个绑定 dstTex（draw）
    GLuint fboRead = createFramebufferWithTexture(srcTexture);
    if (fboRead == 0) {
        LOG_ERROR("GLBridge", "BlitTextureToSurface: 创建读 FBO 失败");
        // 不释放 surface，让调用方 release
        return 0;
    }
    GLuint fboDraw = createFramebufferWithTexture(dstTex);
    if (fboDraw == 0) {
        LOG_ERROR("GLBridge", "BlitTextureToSurface: 创建写 FBO 失败");
        glDeleteFramebuffers(1, &fboRead);
        return 0;
    }

    // 4) 执行 blit
    glBindFramebuffer(GL_READ_FRAMEBUFFER, fboRead);
    glBindFramebuffer(GL_DRAW_FRAMEBUFFER, fboDraw);
    // 复制整个区域
    glBlitFramebuffer(0, 0, width, height,
                      0, 0, width, height,
                      GL_COLOR_BUFFER_BIT, GL_NEAREST);

    // 5) 恢复默认绑定
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    // 6) 清理临时 FBO（保留 dstTex，因为它和 IOSurface 绑定）
    glDeleteFramebuffers(1, &fboRead);
    glDeleteFramebuffers(1, &fboDraw);

    uint32_t sid = IOSurfaceGetID(surface);
    LOG_INFO("GLBridge", [[NSString stringWithFormat:@"BlitTextureToSurface 成功：srcTex=%u -> surfaceID=%u (dstTex=%u)", srcTexture, sid, dstTex] UTF8String]);

    // 注意：不要在这里释放 surface（上层负责 release）。dstTex 保留以维持 GL 与 IOSurface 的关联，
    // 如果你想缓存映射关系，可在这里将 (sid -> dstTex) 记录到哈希表以便后续复用/释放。

    return sid;
}
