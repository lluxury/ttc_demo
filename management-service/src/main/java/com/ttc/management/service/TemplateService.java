package com.ttc.management.service;

import com.alibaba.fastjson2.JSON;
import com.ttc.api.dto.TemplateCreateReq;
import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.repository.KpiTemplateRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;

@Service
@Slf4j
public class TemplateService {

    @Autowired
    private KpiTemplateRepository repository; // JPA接口

    // 1. 生成模板（写入DB，同时写入Redis缓存）
    @CacheEvict(value = "kpi:template", key = "#result.id") // 清空旧缓存
    public KpiTemplateEntity createTemplate(TemplateCreateReq req) {
        KpiTemplateEntity entity = new KpiTemplateEntity();
        entity.setName(req.name());
        entity.setBaseScore(req.baseScore());
        entity.setWeights(JSON.toJSONString(req.weights())); // 用fastjson或jackson
        return repository.save(entity);
    }

    // 2. 查询模板（先查Redis缓存，没有则查DB）
    @Cacheable(value = "kpi:template", key = "#id", unless = "#result == null")
    public KpiTemplateEntity getTemplate(Long id) {
        log.info("【模拟DB查询】从数据库拉取模板ID：{}", id);
        return repository.findById(id).orElse(null);
    }
}