// 包路径：com.ttc.config.CacheConfig
package com.ttc.config;

import com.github.benmanes.caffeine.cache.Caffeine;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.caffeine.CaffeineCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.util.concurrent.TimeUnit;

@Configuration
@EnableCaching  // 开启缓存注解支持（务必保留）
public class CacheConfig {

    @Bean
    public CacheManager cacheManager() {
        CaffeineCacheManager cacheManager = new CaffeineCacheManager();
        cacheManager.setCaffeine(Caffeine.newBuilder()
                .maximumSize(1000)                // 最大缓存条目数
                .expireAfterWrite(10, TimeUnit.MINUTES) // 写入后10分钟过期
                .recordStats()                    // 开启统计（方便调试）
        );
        return cacheManager;
    }
}