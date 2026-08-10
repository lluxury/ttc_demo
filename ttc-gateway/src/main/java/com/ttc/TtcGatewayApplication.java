package com.ttc;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class TtcGatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(TtcGatewayApplication.class, args);
        System.out.println("✅ API 网关 (Gateway) 已启动，端口 8080");
    }
}