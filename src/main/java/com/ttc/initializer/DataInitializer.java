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

    public DataInitializer(KpiTemplateRepository repository, TemplateService templateService) {
        this.repository = repository;
        this.templateService = templateService;
    }

    @Override
    @Transactional
    public void run(ApplicationArguments args) {
        // 检查数据库是否为空
        if (repository.count() == 0) {
            System.out.println("🚀 初始化默认绩效模板...");

            KpiTemplateEntity entity = new KpiTemplateEntity();
            entity.setName("研发月度KPI（默认模板）");
            entity.setBaseScore(100);
            // 权重 JSON
            //entity.setWeights("{\"代码质量\":0.4,\"响应速度\":0.3,\"团队协作\":0.3}");
            entity.setWeights("{\"codeQuality\":0.4,\"responseSpeed\":0.3,\"teamwork\":0.3}");

            KpiTemplateEntity saved = repository.save(entity);
            System.out.println("✅ 模板数据已写入 H2 数据库，ID = " + saved.getId());

            // 重要：主动加载一次到 Redis 缓存（预热）
            // 这样后续计算接口直接命中 Redis，无需再查 DB
            templateService.getTemplate(saved.getId());
            System.out.println("🔥 模板数据已预热至 Redis 缓存！");
        } else {
            System.out.println("⏳ 数据库已有模板数据，跳过初始化。");
        }
    }
}