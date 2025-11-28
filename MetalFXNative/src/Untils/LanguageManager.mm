//
//  LanguageManager.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/27.
//

#import "LanguageManager.h"
#import "Logger.h"
#import <Foundation/Foundation.h>

#pragma mark - 全局缓存

static NSDictionary* g_cachedLanguageData = nil;
static NSString* g_currentLanguage = nil;
static NSString* g_currentLanguageFilePath = nil;

#pragma mark - 内部辅助函数

// 检测系统语言（仅区分中英）
static NSString* DetectSystemLanguage(void) {
    NSString* lang = [[NSLocale preferredLanguages] firstObject];
    return [lang hasPrefix:@"zh"] ? @"zh_cn" : @"en_us";
}

// 从 bundle 或调试目录中查找语言文件
static NSString* FindLanguageFileInBundles(NSString* lang) {
    if (!lang || lang.length == 0) lang = @"en_us";

    NSMutableArray<NSBundle*>* bundles = [NSMutableArray array];

    NSBundle* frameworkBundle = [NSBundle bundleWithIdentifier:@"com.mox.MetalFXNative"];
    if (frameworkBundle) {
        [bundles addObject:frameworkBundle];
    } else {
        NSLog(@"[LanguageManager][DEBUG] Framework bundle not found (com.mox.MetalFXNative).");
    }

    NSBundle* mainBundle = [NSBundle mainBundle];
    if (mainBundle) {
        [bundles addObject:mainBundle];
    } else {
        NSLog(@"[LanguageManager][DEBUG] Main bundle not found.");
    }

    // 从有效的 bundle 中查找语言文件
    for (NSBundle* bundle in bundles) {
        NSString* path = [bundle pathForResource:lang ofType:@"json"];
        if (path) {
            NSLog(@"[LanguageManager][DEBUG] Found language file in bundle: %@", path);
            return path;
        }
    }

#if DEBUG
    // Debug 模式下从构建目录寻找
    NSString* debugDir = [[NSFileManager defaultManager] currentDirectoryPath];
    NSString* debugPath = [debugDir stringByAppendingFormat:
                           @"/MetalFXNative.framework/Resources/%@.json", lang];
    if ([[NSFileManager defaultManager] fileExistsAtPath:debugPath]) {
        NSLog(@"[LanguageManager][DEBUG] Found language file in debug path: %@", debugPath);
        return debugPath;
    }
#endif

    NSLog(@"[LanguageManager][DEBUG] Language file not found for lang=%@", lang);
    return nil;
}

// 自动在指定目录或运行目录创建默认语言文件 lang.json
static NSString* CreateFallbackLanguageFile(NSString* preferredDir) {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* baseDir = preferredDir ?: [fm currentDirectoryPath];
    NSString* langDir = [baseDir stringByAppendingPathComponent:@"lang"];
    NSString* targetPath = [langDir stringByAppendingPathComponent:@"lang.json"];

    [fm createDirectoryAtPath:langDir withIntermediateDirectories:YES attributes:nil error:nil];

    NSString* enPath = FindLanguageFileInBundles(@"en_us");
    if (enPath && [fm fileExistsAtPath:enPath]) {
        [fm removeItemAtPath:targetPath error:nil];
        NSError* err = nil;
        [fm copyItemAtPath:enPath toPath:targetPath error:&err];
        if (!err) {
            LOG_INFO("LanguageManager", "已创建默认语言文件 / Default lang.json created");
        } else {
            LOG_ERROR("LanguageManager", "复制语言模板失败 / Failed to copy language template");
        }
    } else {
        [@"{}" writeToFile:targetPath atomically:YES encoding:NSUTF8StringEncoding error:nil];
        LOG_WARN("LanguageManager", "未找到模板，生成空语言文件 / Created empty lang.json");
    }

    return targetPath;
}

// 解析语言路径（带自动修复）
static NSString* ResolveLanguagePath(NSString* lang) {
    if (!lang) lang = DetectSystemLanguage();

    NSString* path = FindLanguageFileInBundles(lang);
    if (!path) path = FindLanguageFileInBundles(@"en_us");

    // 仍然未找到 → 创建默认语言文件到运行目录
    if (!path) path = CreateFallbackLanguageFile(nil);

    if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
        LOG_ERROR("LanguageManager", "语言文件仍未找到 / Language file not found");
        return nil;
    }

    return path;
}

#pragma mark - 核心逻辑

// 加载语言文件到缓存
static bool LoadLanguageData(void) {
    if (g_cachedLanguageData) return true;

    NSString* lang = g_currentLanguage ?: DetectSystemLanguage();
    NSString* path = g_currentLanguageFilePath ?: ResolveLanguagePath(lang);
    if (!path) return false;

    NSData* data = [NSData dataWithContentsOfFile:path];
    if (!data) {
        LOG_ERROR("LanguageManager", "语言文件读取失败 / Failed to read language file");
        return false;
    }

    NSError* err = nil;
    NSDictionary* dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&err];
    if (err || ![dict isKindOfClass:[NSDictionary class]]) {
        LOG_ERROR("LanguageManager", "语言文件解析失败 / Failed to parse language file");
        return false;
    }

    g_cachedLanguageData = dict;
    g_currentLanguageFilePath = path;
    LOG_INFO("LanguageManager", "语言数据加载成功 / Language data loaded");
    return true;
}

// 设置外部语言文件路径（支持自定义目录与自动兜底）
bool LanguageManager_SetExternalLanguagePath(const char* externalPath) {
    NSFileManager* fm = [NSFileManager defaultManager];
    NSString* basePath = nil;

    if (externalPath && strlen(externalPath) > 0) {
        basePath = [NSString stringWithUTF8String:externalPath];
    }

    BOOL isDir = NO;
    BOOL exists = basePath ? [fm fileExistsAtPath:basePath isDirectory:&isDir] : NO;

    NSString* targetPath = nil;

    if (exists) {
        if (isDir) {
            // 如果传入目录，则在其中创建 lang.json
            targetPath = [basePath stringByAppendingPathComponent:@"lang.json"];
            if (![fm fileExistsAtPath:targetPath]) {
                targetPath = CreateFallbackLanguageFile(basePath);
                LOG_INFO("LanguageManager", "外部路径中创建了语言文件 / Created lang.json in external dir");
            }
        } else {
            // 已指定现成的文件
            targetPath = basePath;
        }
    } else {
        // 路径无效 → 回退到运行目录
        LOG_WARN("LanguageManager", "外部路径无效，使用运行目录创建 / External path invalid, fallback to current dir");
        targetPath = CreateFallbackLanguageFile(nil);
    }

    if (!targetPath || ![fm fileExistsAtPath:targetPath]) {
        LOG_ERROR("LanguageManager", "无法设置外部语言路径 / Failed to set external language path");
        return false;
    }

    g_currentLanguageFilePath = targetPath;
    g_cachedLanguageData = nil;
    return true;
}

// 获取翻译后的文本
const char* LanguageManager_GetTranslatedMessage(const char* msgKey) {
    if (!msgKey) return "(null)";
    if (!LoadLanguageData()) return msgKey;

    NSString* key = [NSString stringWithUTF8String:msgKey];
    NSString* text = g_cachedLanguageData[key];
    return text ? strdup([text UTF8String]) : msgKey;
}
 
// 获取当前语言代码
const char* LanguageManager_GetCurrentLanguage(void) {
    if (!g_currentLanguage)
        g_currentLanguage = DetectSystemLanguage();
    return [g_currentLanguage UTF8String];
}

// 初始化与清理
void LanguageManager_Initialize(void) {
    g_currentLanguage = DetectSystemLanguage();
    g_currentLanguageFilePath = ResolveLanguagePath(g_currentLanguage);
    LoadLanguageData();
    LOG_INFO("LanguageManager", "LanguageManager 初始化完成 / Initialized");
}

void LanguageManager_Cleanup(void) {
    g_cachedLanguageData = nil;
    g_currentLanguageFilePath = nil;
    g_currentLanguage = nil;
}
