//
//  MetalContext.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#import "MetalContext.h"
#import "Logger.h"

static id<MTLDevice> g_device = nil;
static id<MTLCommandQueue> g_commandQueue = nil;

bool MetalContext_Initialize(void) {
    g_device = MTLCreateSystemDefaultDevice();
    if (!g_device) {
        LOG_ERROR("MetalContext", "MetalContext_001_DEVICE_CREATION_FAILED");
        return false;
    }
    g_commandQueue = [g_device newCommandQueue];
    if (!g_commandQueue) {
        LOG_ERROR("MetalContext", "MetalContext_002_COMMAND_QUEUE_CREATION_FAILED");
        return false;
    }

    LOG_INFO("MetalContext", "MetalContext_003_INITIALIZATION_SUCCESS");

    // 检查 MetalFX 支持并记录
    if (MetalContext_IsMetalFXSupported()) {
        LOG_INFO("MetalContext", "MetalContext_004_METALFX_SUPPORTED");
    } else {
        LOG_WARN("MetalContext", "MetalContext_005_METALFX_NOT_SUPPORTED");
    }

    return true;
}

id<MTLDevice> MetalContext_GetDevice(void) {
    return g_device;
}

id<MTLCommandQueue> MetalContext_GetCommandQueue(void) {
    return g_commandQueue;
}


id<MTLTexture> MetalContext_CreateTexture2D(int width, int height, MTLPixelFormat format) {
    if (!g_device || width <= 0 || height <= 0) {
        LOG_ERROR("MetalContext", "MetalContext_006_TEXTURE_CREATION_FAILED");
        return nil;
    }

    MTLTextureDescriptor* descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:format
                                                                                          width:width
                                                                                         height:height
                                                                                      mipmapped:NO];
    descriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite | MTLTextureUsageRenderTarget;

    id<MTLTexture> texture = [g_device newTextureWithDescriptor:descriptor];
    if (!texture) {
        LOG_ERROR("MetalContext", "MetalContext_007_TEXTURE_CREATION_ERROR");
        return nil;
    }

    LOG_INFO("MetalContext", "MetalContext_008_TEXTURE_CREATION_SUCCESS");
    return texture;
}

bool MetalContext_IsMetalFXSupported(void) {
    if (!g_device) {
        return false;
    }

    // 检查 Metal 版本（MetalFX 需要 Metal 3+）
    if (![g_device supportsFamily:MTLGPUFamilyMetal3]) {
        return false;
    }

    // 检查是否支持超分功能
    // 注意：具体的 MetalFX API 检查可能需要更详细的版本检查
    // 这里使用设备家族作为基础检查

    LOG_INFO("MetalContext", "MetalContext_004_METALFX_SUPPORTED");
    return true;
}

void MetalContext_Shutdown(void) {
    g_commandQueue = nil;
    g_device = nil;
    LOG_INFO("MetalContext", "MetalContext_009_SHUTDOWN_SUCCESS");
}

