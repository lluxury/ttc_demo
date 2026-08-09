package com.ttc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;

@SpringBootApplication
@EnableCaching
public class SpmApplication {
    public static void main(String[] args) {
        SpringApplication.run(SpmApplication.class, args);
        System.out.println("✅ 绩效平台启动成功！");
    }
}