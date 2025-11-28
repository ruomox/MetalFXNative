//
//  Logger.mm
//  MetalFXNative
//
//  Created by Mox on 2025/10/17.
//

#import "Logger.h"
#import "LanguageManager.h"
#import <Foundation/Foundation.h>

/// 获取翻译后的消息文本
static const char* Logger_GetMessage(const char* msgKey) {
    if (!msgKey) return "(null)";
    const char* translated = LanguageManager_GetTranslatedMessage(msgKey);
    return translated ? translated : msgKey;
}

/// 信息日志
void LOG_INFO(const char* tag, const char* msgKey) {
    const char* msg = Logger_GetMessage(msgKey);
    NSLog(@"[%s] INFO: %s", tag, msg);
    if (msg != msgKey) free((void*)msg);
}

/// 警告日志
void LOG_WARN(const char* tag, const char* msgKey) {
    const char* msg = Logger_GetMessage(msgKey);
    NSLog(@"[%s] WARNING: %s", tag, msg);
    if (msg != msgKey) free((void*)msg);
}

/// 错误日志
void LOG_ERROR(const char* tag, const char* msgKey) {
    const char* msg = Logger_GetMessage(msgKey);
    NSLog(@"[%s] ERROR: %s", tag, msg);
    if (msg != msgKey) free((void*)msg);
}
