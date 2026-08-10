package com.ttc.initializer;

import com.ttc.management.entity.KpiTemplateEntity;
import com.ttc.management.repository.KpiTemplateRepository;
import com.ttc.management.service.TemplateService;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

@Component
public class DataInitializer implements ApplicationRunner {

    private final KpiTemplateRepository repository;
    private final TemplateService templateService;

    // 构造器注入（推荐）
    public DataInitializer(KpiTemplateRepository repository, TemplateService templateService) {
        this.repository = repository;
        this.templateService = templateService;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        // 检查数据库是否为空
        if (repository.count() == 0) {
            System.out.println("🚀 [Management服务] 初始化默认绩效模板...");

            // 创建一个 ID=1 的默认模板（英文键，匹配前端/业务服务的请求）
            KpiTemplateEntity entity = new KpiTemplateEntity();
            entity.setName("研发月度KPI（默认模板）");
            entity.setBaseScore(100);
            entity.setWeights("{\"codeQuality\":0.4,\"responseSpeed\":0.3,\"teamwork\":0.3}");

            // 保存到 H2 数据库
            KpiTemplateEntity saved = repository.save(entity);
            System.out.println("✅ 模板数据已写入 H2 数据库，ID = " + saved.getId());

            // ★ 立即预热到 Caffeine 本地缓存（这样 business-service 第一次远程调用就能拿到缓存数据）
            templateService.getTemplate(saved.getId());
            System.out.println("🔥 模板数据已预热至 Caffeine 本地缓存！");
        } else {
            System.out.println("⏳ [Management服务] 数据库已有模板数据，跳过初始化。");
        }
    }
}