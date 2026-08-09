// 包路径：com.ttc.business.service.CalculateService
package com.ttc.business.service;

import com.alibaba.fastjson2.JSON;
import com.alibaba.fastjson2.TypeReference;
import com.ttc.api.dto.CalcReq;
import com.ttc.api.dto.CalcResult;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.service.TemplateService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.locks.ReentrantLock;

@Service
@Slf4j
public class CalculateService {

    @Autowired
    private TemplateService templateService;

    // ★ 本地锁池：为每个员工ID维护一把锁，确保同一员工的计算串行执行
    private final ConcurrentHashMap<String, ReentrantLock> lockMap = new ConcurrentHashMap<>();

    public CalcResult calculateScore(CalcReq req) {
        String employeeId = String.valueOf(req.employeeId());
        
        // 获取或创建该员工的专属锁
        ReentrantLock lock = lockMap.computeIfAbsent(employeeId, k -> new ReentrantLock());
        
        try {
            // 尝试加锁（立即返回false或等待，这里使用tryLock带超时）
            if (lock.tryLock(3, java.util.concurrent.TimeUnit.SECONDS)) {
                try {
                    log.info("【获取本地锁成功】开始计算员工: {}", employeeId);

                    // 1. 获取模板（此时走 Caffeine 缓存，第二次调用极快）
                    KpiTemplateEntity template = templateService.getTemplate(req.templateId());
                    if (template == null) {
                        throw new RuntimeException("模板不存在");
                    }

                    // 2. 解析权重
                    Map<String, Double> weightMap = JSON.parseObject(template.getWeights(),
                            new TypeReference<Map<String, Double>>() {});
                    Map<String, Integer> scoreMap = req.scoreMap();

                    // 3. Java 17 计算加权总分
                    int totalScore = 0;
                    for (Map.Entry<String, Integer> entry : scoreMap.entrySet()) {
                        Double weight = weightMap.getOrDefault(entry.getKey(), 0.0);
                        totalScore += (int) (entry.getValue() * weight);
                    }

                    // 4. Java 17 Switch 判定等级
                    String grade = switch (totalScore / 10) {
                        case 10, 9 -> "S";
                        case 8 -> "A";
                        case 7 -> "B";
                        case 6 -> "C";
                        default -> "D";
                    };

                    log.info("【计算结果】员工{} 总分: {}, 等级: {}", employeeId, totalScore, grade);
                    return new CalcResult(employeeId, grade, totalScore);

                } finally {
                    lock.unlock();
                    log.info("【释放本地锁】员工 {} 计算完成", employeeId);
                }
            } else {
                log.warn("【获取锁超时】员工 {} 的计算任务正在执行中，稍后重试", employeeId);
                return null;
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("锁等待被中断", e);
            return null;
        }
    }
}