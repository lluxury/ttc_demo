package com.ttc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class TtcManagementApplication {
    public static void main(String[] args) {
        SpringApplication.run(TtcManagementApplication.class, args);
        System.out.println("✅ 管理服务 (Management) 已启动，端口 8081");
    }
}