//
//  IOSurfaceMetalInterop.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/27.
//

#import "IOSurfaceMetalInterop.h"
#import <CoreVideo/CoreVideo.h>
#import <IOSurface/IOSurface.h>
#import "Logger.h"

id<MTLTexture> IOSurfaceMetalInterop_CreateTextureFromSurface(IOSurfaceRef surface, id<MTLDevice> device) {
    if (!device || !surface) {
        LOG_ERROR("IOSurfaceMetalInterop", "IOSurfaceMetalInterop_001_INVALID_PARAMETERS");
        return nil;
    }

    // 检查格式兼容性
    if (!IOSurfaceMetalInterop_IsFormatCompatible(surface)) {
        LOG_ERROR("IOSurfaceMetalInterop", "IOSurfaceMetalInterop_002_FORMAT_INCOMPATIBLE");
        return nil;
    }

    MTLTextureDescriptor* textureDescriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                                 width:IOSurfaceGetWidth(surface)
                                                                                                height:IOSurfaceGetHeight(surface)
                                                                                             mipmapped:NO];

    // 关键：设置纹理为 IOSurface 支持
    textureDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;

    id<MTLTexture> texture = [device newTextureWithDescriptor:textureDescriptor iosurface:surface plane:0];
    if (!texture) {
        LOG_ERROR("IOSurfaceMetalInterop", "IOSurfaceMetalInterop_003_TEXTURE_CREATION_FAILED");
        return nil;
    }

    LOG_INFO("IOSurfaceMetalInterop", "IOSurfaceMetalInterop_004_TEXTURE_CREATION_SUCCESS");
    return texture;
}

bool IOSurfaceMetalInterop_IsFormatCompatible(IOSurfaceRef surface) {
    if (!surface) return false;

    OSType format = IOSurfaceGetPixelFormat(surface);
    // 检查是否支持 Metal 的常用格式
    switch (format) {
        case kCVPixelFormatType_32BGRA:
        case kCVPixelFormatType_32RGBA:
        case kCVPixelFormatType_64RGBAHalf:
        case kCVPixelFormatType_128RGBAFloat:
            return true;
        default:
            LOG_WARN("IOSurfaceMetalInterop", "IOSurfaceMetalInterop_005_UNSUPPORTED_FORMAT");
            return false;
    }
}

uint32_t IOSurfaceMetalInterop_GetPixelFormat(IOSurfaceRef surface) {
    if (!surface) return 0;
    return IOSurfaceGetPixelFormat(surface);
}

void IOSurfaceMetalInterop_GetDimensions(IOSurfaceRef surface, int* width, int* height) {
    if (!surface || !width || !height) return;
    *width = (int)IOSurfaceGetWidth(surface);
    *height = (int)IOSurfaceGetHeight(surface);
}
