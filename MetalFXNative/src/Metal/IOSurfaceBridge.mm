//
//  IOSurfaceBridge.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#import <CoreVideo/CoreVideo.h>
#import "IOSurfaceBridge.h"
#import "Logger.h"

IOSurfaceRef IOSurfaceBridge_CreateIOSurfaceWithWidth(int width, int height) {
    NSDictionary* props = @{
        (NSString*)kIOSurfaceWidth: @(width),
        (NSString*)kIOSurfaceHeight: @(height),
        (NSString*)kIOSurfacePixelFormat: @(kCVPixelFormatType_32BGRA),
        (NSString*)kIOSurfaceBytesPerElement: @4
    };

    IOSurfaceRef surface = IOSurfaceCreate((CFDictionaryRef)props);
    if (!surface) {
        LOG_ERROR("IOSurfaceBridge", "IOSurfaceBridge_001_CREATION_FAILED");
        return nil;
    }
    LOG_INFO("IOSurfaceBridge", "IOSurfaceBridge_002_CREATION_SUCCESS");
    return surface;
}

void IOSurfaceBridge_LogInfo(IOSurfaceRef surface) {
    if (!surface) return;
    size_t w = IOSurfaceGetWidth(surface);
    size_t h = IOSurfaceGetHeight(surface);
    uint32_t id = IOSurfaceGetID(surface);
    LOG_INFO("IOSurfaceBridge", [[NSString stringWithFormat:@"IOSurfaceBridge_003_SURFACE_INFO: width:%zu height:%zu ID:%u", w, h, id] UTF8String]);
}

bool IOSurfaceBridge_LockSurface(IOSurfaceRef surface) {
    if (!surface) return false;
    kern_return_t result = IOSurfaceLock(surface, kIOSurfaceLockReadOnly, NULL);
    if (result != KERN_SUCCESS) {
        LOG_ERROR("IOSurfaceBridge", [[NSString stringWithFormat:@"IOSurfaceBridge_004_LOCK_FAILED: %d", result] UTF8String]);
        return false;
    }
    return true;
}

void IOSurfaceBridge_UnlockSurface(IOSurfaceRef surface) {
    if (!surface) return;
    IOSurfaceUnlock(surface, kIOSurfaceLockReadOnly, NULL);
}

bool IOSurfaceBridge_IsFormatCompatible(IOSurfaceRef surface) {
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
            LOG_WARN("IOSurfaceBridge", [[NSString stringWithFormat:@"IOSurfaceBridge_005_UNSUPPORTED_FORMAT: %u", format] UTF8String]);
            return false;
    }
}

OSType IOSurfaceBridge_GetPixelFormat(IOSurfaceRef surface) {
    if (!surface) return 0;
    return IOSurfaceGetPixelFormat(surface);
}

void IOSurfaceBridge_GetDimensions(IOSurfaceRef surface, int* width, int* height) {
    if (!surface || !width || !height) return;
    *width = (int)IOSurfaceGetWidth(surface);
    *height = (int)IOSurfaceGetHeight(surface);
}

void IOSurfaceBridge_Release(IOSurfaceRef surface) {
    if (!surface) return;
    CFRelease(surface);
    LOG_INFO("IOSurfaceBridge", "IOSurfaceBridge_006_RELEASE_SUCCESS");
}
