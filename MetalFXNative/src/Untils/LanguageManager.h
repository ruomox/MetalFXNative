//
//  LanguageManager.h
//  MetalFXNative
//
//  Created by Mox on 2025/10/27.
//

#ifndef LanguageManager_h
#define LanguageManager_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif


/// 获取当前有效的语言代码
/// @return 当前有效的语言代码字符串指针
const char* LanguageManager_GetCurrentLanguage(void);

/// 设置外部语言文件路径
/// @param externalPath 外部语言文件路径（可为NULL，使用默认路径）
/// @return 操作是否成功
bool LanguageManager_SetExternalLanguagePath(const char* externalPath);

/// 获取翻译后的消息
/// @param msgKey 消息键值
/// @return 翻译后的消息字符串指针
const char* LanguageManager_GetTranslatedMessage(const char* msgKey);

/// 初始化LanguageManager
void LanguageManager_Initialize(void);

/// 清理LanguageManager资源
void LanguageManager_Cleanup(void);

#ifdef __cplusplus
}
#endif

#endif /* LanguageManager_h */
