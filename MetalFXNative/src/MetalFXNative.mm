//
//  MetalFXNative.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#import "MetalFXNative.h"
#import "MetalContext.h"
#import "IOSurfaceBridge.h"
#import "Logger.h"
#import "LanguageManager.h"

static id<MTLDevice> metalDevice = nil;

bool MetalFXNative_Init(void) {
    // 初始化LanguageManager
    //LanguageManager_Initialize();
    
    LOG_INFO("MetalFXNative", "MetalFXNative_001_INITIALIZING");
    bool ok = MetalContext_Initialize();
    if (!ok) {
        LOG_ERROR("MetalFXNative", "MetalFXNative_002_INITIALIZATION_FAILED");
        return false;
    }

    LOG_INFO("MetalFXNative", "MetalFXNative_003_INITIALIZATION_SUCCESS");
    return true;
}



void* MetalFXNative_CreateSurface(size_t width, size_t height) {
    IOSurfaceRef surface = IOSurfaceBridge_CreateIOSurfaceWithWidth((int)width, (int)height);
    if (!surface) {
        LOG_ERROR("MetalFXNative", "MetalFXNative_004_SURFACE_CREATION_FAILED");
        return NULL;
    }
    IOSurfaceBridge_LogInfo(surface);
    return (void*)surface;
}

void MetalFXNative_ReleaseSurface(void* surfacePtr) {
    IOSurfaceRef surface = (IOSurfaceRef)surfacePtr;
    IOSurfaceBridge_Release(surface);
}

void MetalFXNative_Shutdown(void) {
    MetalContext_Shutdown();
    LanguageManager_Cleanup();
    LOG_INFO("MetalFXNative", "MetalFXNative_005_SHUTDOWN_SUCCESS");
}


bool MetalFXNative_SetExternalLanguagePath(const char* externalPath) {
    return LanguageManager_SetExternalLanguagePath(externalPath);
}


